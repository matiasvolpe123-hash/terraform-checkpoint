package com.example.streaming;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.amazonaws.services.kinesisanalytics.runtime.KinesisAnalyticsRuntime;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.functions.AggregateFunction;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.java.utils.ParameterTool;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.streaming.api.functions.windowing.ProcessWindowFunction;
import org.apache.flink.util.Collector;
import org.apache.flink.streaming.connectors.kinesis.FlinkKinesisConsumer;
import org.apache.flink.streaming.connectors.kinesis.config.ConsumerConfigConstants;

import java.time.Duration;
import java.time.Instant;
import java.util.Properties;
import java.util.Map;
import java.util.HashMap;

/** One-minute event-time temperature summaries, keyed by sensor_id. */
public final class SensorAggregationJob {
    private static final ObjectMapper JSON = new ObjectMapper();

    public static void main(String[] args) throws Exception {
        Map<String, Properties> applicationProperties = KinesisAnalyticsRuntime.getApplicationProperties();
        Properties flinkProperties = applicationProperties.getOrDefault("FlinkApplicationProperties", new Properties());
        Map<String, String> propertyMap = new HashMap<>();
        for (String name : flinkProperties.stringPropertyNames()) propertyMap.put(name, flinkProperties.getProperty(name));
        ParameterTool params = ParameterTool.fromMap(propertyMap)
                .mergeWith(ParameterTool.fromArgs(args));
        String streamName = required(params, "stream", "STREAM_NAME");
        String region = params.get("region", System.getenv().getOrDefault("AWS_REGION", "us-east-2"));
        int parallelism = params.getInt("PARALLELISM", 2);
        long windowMinutes = params.getLong("WINDOW_MINUTES", 1);
        long outOfOrderSeconds = params.getLong("OUT_OF_ORDER_SECONDS", 10);

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(parallelism);
        env.getConfig().setGlobalJobParameters(params);

        Properties consumerConfig = new Properties();
        consumerConfig.setProperty(ConsumerConfigConstants.AWS_REGION, region);
        consumerConfig.setProperty(ConsumerConfigConstants.STREAM_INITIAL_POSITION,
                ConsumerConfigConstants.InitialPosition.TRIM_HORIZON.name());
        DataStream<String> raw = env.addSource(new FlinkKinesisConsumer<>(streamName,
                new SimpleStringSchema(), consumerConfig)).name("kinesis-sensor-events");

        DataStream<SensorEvent> events = raw.map(SensorAggregationJob::parse)
                .returns(SensorEvent.class)
                .filter(event -> event != null)
                .assignTimestampsAndWatermarks(WatermarkStrategy
                        .<SensorEvent>forBoundedOutOfOrderness(Duration.ofSeconds(outOfOrderSeconds))
                        .withTimestampAssigner((event, previousTimestamp) -> event.eventTimeMillis));

        events.keyBy(event -> event.sensorId)
                .window(TumblingEventTimeWindows.of(Time.minutes(windowMinutes)))
                .aggregate(new TemperatureAggregate(), new WindowMetadata())
                .name("sensor-temperature-window-aggregation")
                .print("temperature-summary");

        env.execute("kinesis-sensor-temperature-aggregation");
    }

    private static String required(ParameterTool params, String parameter, String environmentVariable) {
        String propertyName = parameter.equals("stream") ? "STREAM_NAME"
                : parameter.equals("region") ? "AWS_REGION" : parameter;
        String value = params.get(propertyName, System.getenv(environmentVariable));
        if (value == null || value.isBlank()) throw new IllegalArgumentException(
                "Set --" + parameter + " or " + environmentVariable);
        return value;
    }

    private static SensorEvent parse(String json) {
        try {
            JsonNode node = JSON.readTree(json);
            String sensor = node.path("sensor_id").asText("");
            JsonNode temperature = node.path("temperatura");
            if (sensor.isBlank() || !temperature.isNumber()) return null;
            JsonNode time = node.has("event_time") ? node.path("event_time") : node.path("timestamp");
            long eventTime = time.isNumber() ? time.asLong()
                    : time.isTextual() ? Instant.parse(time.asText()).toEpochMilli() : System.currentTimeMillis();
            return new SensorEvent(sensor, temperature.asDouble(), eventTime);
        } catch (Exception ignored) {
            return null;
        }
    }

    public static final class SensorEvent {
        public String sensorId;
        public double temperature;
        public long eventTimeMillis;
        public SensorEvent() {}
        SensorEvent(String sensorId, double temperature, long eventTimeMillis) {
            this.sensorId = sensorId; this.temperature = temperature; this.eventTimeMillis = eventTimeMillis;
        }
    }

    public static final class Summary {
        public String sensorId;
        public long windowStartMillis;
        public long windowEndMillis;
        public long count;
        public double sum;
        public double min;
        public double max;
        public Summary() {}
        Summary(String sensorId, long start, long end, long count, double sum, double min, double max) {
            this.sensorId = sensorId; this.windowStartMillis = start; this.windowEndMillis = end;
            this.count = count; this.sum = sum; this.min = min; this.max = max;
        }
        @Override public String toString() {
            return "{\"sensor_id\":\"" + sensorId + "\",\"window_start_ms\":" + windowStartMillis
                    + ",\"window_end_ms\":" + windowEndMillis + ",\"count\":" + count
                    + ",\"avg_temperature\":" + (sum / count) + ",\"min_temperature\":" + min
                    + ",\"max_temperature\":" + max + "}";
        }
    }

    public static final class TemperatureAggregate implements AggregateFunction<SensorEvent, Summary, Summary> {
        @Override public Summary createAccumulator() { return new Summary(); }
        @Override public Summary add(SensorEvent event, Summary acc) {
            if (acc.count == 0) { acc.sensorId = event.sensorId; acc.min = event.temperature; acc.max = event.temperature; }
            acc.count++; acc.sum += event.temperature; acc.min = Math.min(acc.min, event.temperature);
            acc.max = Math.max(acc.max, event.temperature); return acc;
        }
        @Override public Summary getResult(Summary acc) { return acc; }
        @Override public Summary merge(Summary a, Summary b) {
            a.count += b.count; a.sum += b.sum; a.min = Math.min(a.min, b.min); a.max = Math.max(a.max, b.max);
            if (a.sensorId == null) a.sensorId = b.sensorId; return a;
        }
    }

    public static final class WindowMetadata extends ProcessWindowFunction<Summary, Summary, String, TimeWindow> {
        @Override public void process(String sensorId, Context context, Iterable<Summary> summaries,
                                      Collector<Summary> out) {
            Summary summary = summaries.iterator().next();
            summary.sensorId = sensorId;
            summary.windowStartMillis = context.window().getStart();
            summary.windowEndMillis = context.window().getEnd();
            out.collect(summary);
        }
    }
}
