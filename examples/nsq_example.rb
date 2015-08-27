require "avro"
require "diplomat"
require "nsq"

class AvroProducer
  MESSAGE_VERSION = 1

  attr_reader :nsq_producer, :topic

  def initialize topic
    @topic = topic
    @nsq_producer = Nsq::Producer.new topic: topic
  end

  def write datum, schema
    canonical_schema = Avro::Schema.parse schema
    schema_string = canonical_schema.to_s
    schema_md5 = Digest::MD5.hexdigest schema_string
    register_schema schema_md5, schema_string
    nsq_producer.write compose_message(datum, schema_md5, canonical_schema)
  end

  private

  def compose_message datum, schema_md5, canonical_schema
    [MESSAGE_VERSION, schema_md5, encode_datum(datum, canonical_schema)].pack 'CH32a*'
  end

  def encode_datum datum, canonical_schema
    buffer = StringIO.new
    encoder = Avro::IO::BinaryEncoder.new buffer
    writer = Avro::IO::DatumWriter.new canonical_schema
    writer.write datum, encoder
    buffer.rewind
    buffer.read
  end

  def register_schema schema_md5, schema_string
    begin
      Diplomat.get "schemas/md5/#{schema_md5}"
    rescue Diplomat::KeyNotFound
      Diplomat.put "schemas/md5/#{schema_md5}", schema_string
    end
  end
end

class AvroConsumer
  attr_reader :channel, :nsq_consumer, :topic

  def initialize topic, channel
    @topic, @channel = topic, channel
    @nsq_consumer = Nsq::Consumer.new topic: topic, channel: channel
    @consuming = false
    @schemas = {}
  end

  def pop
    msg = nsq_consumer.pop
    version, schema_md5, encoded_datum = decompose_message msg.body
    canonical_schema = schema_for schema_md5
    decoded_message = decode_datum encoded_datum, canonical_schema
    msg.finish
    decoded_message
  end

  private

  def decode_datum encoded_datum, canonical_schema
    read_buffer = StringIO.new encoded_datum
    decoder = Avro::IO::BinaryDecoder.new read_buffer
    reader = Avro::IO::DatumReader.new canonical_schema
    reader.read decoder
  end

  def decompose_message raw_message
    raw_message.unpack "CH32a*"
  end

  def load_schema schema_md5
    schema_string = Diplomat.get "schemas/md5/#{schema_md5}"
    @schemas[schema_md5] = Avro::Schema.parse schema_string
  end

  def schema_for schema_md5
    load_schema schema_md5 unless @schemas.key? schema_md5
    @schemas.fetch schema_md5
  end
end

SCHEMA = <<-JSON
{ "type": "record",
  "name": "User",
  "fields" : [
    {"name": "username", "type": "string"},
    {"name": "age", "type": "int"},
    {"name": "verified", "type": "boolean", "default": "false"}
]}
JSON

avro_prod = AvroProducer.new 'foo-users'
datum = {"username" => "foo", "age" => 42, "verified" => true}
p [:sending, datum]
avro_prod.write datum, SCHEMA

avro_cons = AvroConsumer.new 'foo-users', 'foo-channel'
read_message = avro_cons.pop
p [:received, read_message]


version = 1

# Parse and register the schema
canonical_schema = Avro::Schema.parse SCHEMA
canonical_schema_string = canonical_schema.to_s
schema_md5 = Digest::MD5.hexdigest canonical_schema_string
Diplomat.put "schemas/md5/#{schema_md5}", canonical_schema_string

datum = {"username" => "foo", "age" => 42, "verified" => true}

# Encode the datum
buffer = StringIO.new
encoder = Avro::IO::BinaryEncoder.new buffer
writer = Avro::IO::DatumWriter.new canonical_schema
writer.write datum, encoder
buffer.rewind
encoded_datum = buffer.read


# Compose the message
raw_message = [version, schema_md5, encoded_datum].pack 'CH32a*'



topic = "example-users"
channel = "example-reader"

puts "Creating producer on topic '#{topic}'"
producer = Nsq::Producer.new topic: topic

puts "Creating consumer on topic '#{topic}' with channel '#{channel}'"
consumer = Nsq::Consumer.new topic: topic, channel: channel

# Send the message
puts "Publishing message (size #{raw_message.size})"
puts "  #{datum}"
producer.write raw_message


puts "Consuming message"
msg = consumer.pop
msg.finish

read_version, read_md5, read_encoded_datum = msg.body.unpack "CH32a*"

read_schema = Diplomat.get "schemas/md5/#{schema_md5}"
read_canonical_schema = Avro::Schema.parse read_schema

read_buffer = StringIO.new read_encoded_datum
decoder = Avro::IO::BinaryDecoder.new read_buffer
reader = Avro::IO::DatumReader.new read_canonical_schema
read_datum = reader.read decoder

puts "  #{read_datum}"


puts "Terminating producer"
producer.terminate

puts "Terminating consumer"
consumer.terminate
