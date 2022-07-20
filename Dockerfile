FROM amazon/aws-for-fluent-bit:2.25.1
COPY fluentbit/fluentbit-custom.conf /fluent-bit/etc/extra.conf
