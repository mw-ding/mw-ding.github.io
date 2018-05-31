---
title: "Insight.io Tech Stack (3) - Infrastructure and DevOps"
date: 2018-05-29T23:54:28-07:00
draft: true
---

The last post [Insight.io Tech Stack (2) - Serving and Analysis Pipeline]({{< ref "insightio-serving-and-analysis-pipeline.md">}})
covers mostly how our serving and analysis logics are distributed in our stack.
However, to make sure the entire stack works together reliably as a successful
product, there are much more issues to be addressed:

1. **How to log, monitor and profile all these components.**
2. **On which infrastructre platform to host the stack and how to orchestrate on top of it.**
3. **How to package and release services.**
4. **What kind of developer tools to use to maximize developement efficiency.**

These are all the aspects this post is going to talk about. In the meanwhile, you
can refer to the earliest post [Insight.io Tech Stack (1) - RabbitMQ Practices in Insight.io]({{< ref "insightio-rabbitmq-usage.md" >}}) to find out the original
motivation behind these posts.

## Logging & Monitoring

Since most of our stacks use Scala, logging is fairly straight-forward with *slf4j*
binding. To make all the logs easy to access and searchable, we adopted the
[*Elastic-Logstash-Kibana (ELK) Stack*](https://www.elastic.co/elk-stack) to
accommodate all the logs. *slf4j* is configured to redirect all the logs to
*Logstash*, which is resposible to index all the logs into *ElasticSearch*. Then
*Kibana* is the frontend portal to search all the logs.

![ELK](/img/insightio-infra-elk.png)

In most of the time when you resort to logs, you are looking for exceptions. To better
manage and track serving exceptions, we use [*Sentry*](https://sentry.io) to structurely log
exceptions. It helps to provide additional stats regarding different type of exceptions and
can automatically create and track exceptions handling with GitHub issues.

![Sentry](/img/insightio-infra-sentry.png)

To monitor the status of all components in the stack, we use [*Datadog*](https://www.datadoghq.com/)
to collect all their realtime performance for our SaaS version. (For on-premise version stack,
we use [*Prometheus*](https://prometheus.io), an open-source alternatives of Google *Borgmon*, to track timeseries service performance data.). For our micro services,
*Finagle* and JVM stats are collected with minimum effort. ElasticSearch, MongoDB, Redis and
RabbitMQ instances have built-in support in *Datadog*. Also, we can add customized metrics
inside each services.

![Datadog](/img/insightio-infra-datadog.png)

To trace how a request is going through all the services, we use [*Zipkin*]
(https://zipkin.io), an open-source alternative of [*Google Dapper*]
(https://ai.google/research/pubs/pub36356). It can be integrated with *Finagle* with trivial
work. However, to make sure it integrates with *RabbitMQ*, we did some plumbing work as
described in [Insight.io Tech Stack (1) - RabbitMQ Practices in Insight.io]({{< ref "insightio-rabbitmq-usage.md" >}}).

![Zipkin](https://zipkin.io/public/img/web-screenshot.png)

## Cluster Infrastructure

We use [*Amazon Web Services (AWS)*](https://aws.amazon.com) extensively, including but not 
limit to *EC2*, *S3*, *Route53*, *ECR*, *ELB*, *CloudFront* etc. For *EC2* instances, we
use a mixture of reserved and spot instances to reduce the cost. Our production cluster is
placed in Japan to serve both U.S. and China, the 2 places where most of our users come from,
to avoid the extra efforts to maintain 2 clusters. In addition to the production cluster, we
also maintain 2 staging cluster for our internal usage in North America.

To echo [*Infrastructure as Code*](https://en.wikipedia.org/wiki/Infrastructure_as_Code) philosophy
and better provision these AWS clusters and services, we adopt [*Kubernetes (k8s)*](https://kubernetes.io)
and use [*kops*](https://github.com/kubernetes/kops) to launch and manage k8s clusters on AWS.

Most of the micro-services are deployed as stateless instances (a *Deployment* in k8s' concept) to be
scaled and scheduled easier, with few services stateful (*StatefulSet*). All these services in 
production cluster are
configured to be *High Available (HA)* with multiple replications behind *Elastic Load Balancer
(ELB)* via *Services* in k8s.


For service configuration files, we use [*HOCON (Human-Optimized Config Object Notation*](https://github.com/lightbend/config/blob/master/HOCON.md). Its support of inheritance benefits
us a lot in managing multiple sets of service configurations for different clusters with minimum
effort. In 

For on-premise version, things become simpler and *DockerCompose* is good enough to bring up
our stack anywhere.


## Packaging & Release

## Development Tools

