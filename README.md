BOSH release to run rsyslog-kafka
=======================

Background
----------

### What is rsyslog-kafka?

This release integrates the omkafka module from rsyslog to forward your logs to a kafka cluster.

Usage
-----

To use this bosh release, first upload it to your bosh:

```
bosh upload release https://github.com/hybris/rsyslog-kafka-boshrelease
```

For [bosh-lite](https://github.com/cloudfoundry/bosh-lite), you can quickly create a deployment manifest & deploy a cluster:

```
templates/make_manifest warden
bosh -n deploy
```

For AWS EC2, create a single VM:

```
templates/make_manifest aws-ec2
bosh -n deploy
```

### Override security groups

For AWS & Openstack, the default deployment assumes there is a `default` security group. If you wish to use a different security group(s) then you can pass in additional configuration when running `make_manifest` above.

Create a file `my-networking.yml`:

```yaml
---
networks:
  - name: rsyslog-kafka1
    type: dynamic
    cloud_properties:
      security_groups:
        - rsyslog-kafka
```

Where `- rsyslog-kafka` means you wish to use an existing security group called `rsyslog-kafka`.

You now suffix this file path to the `make_manifest` command:

```
templates/make_manifest openstack-nova my-networking.yml
bosh -n deploy
```

### Properties

```yaml
---
properties:
  rsyslog_kafka:
    brokers:
      - localhost:9092  # required - Array of kafka servers
    topic: kafka_topic  # required - Kafka topic
    org: myorg          # required
    space: myspace      # default to bosh deployment name
    service: myservice  # default to bosh job name
```
