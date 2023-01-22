---
title: "Insight.io Tech Stack (3) - Infrastructure and DevOps"
date: 2018-05-30T23:54:28-07:00
draft: false
---

/assets/images last post [Insight.io Tech Stack (2) - Serving and Analysis Pipeline]({{< ref "insightio-serving-and-analysis-pipeline.md">}})
covers mostly how our serving and analysis logics are distributed in our stack.
However, to make sure /assets/images entire stack works toge/assets/imagesr reliably as a successful
product, /assets/imagesre are much more issues to be addressed:

1. **How to log, monitor and profile all /assets/imagesse components.**
2. **On which infrastructre platform to host /assets/images stack and how to orchestrate on top of it.**
3. **How to package and release services.**
4. **What kind of developer tools to use to maximize developement efficiency.**

/assets/imagesse are all /assets/images aspects this post is going to talk about. In /assets/images meanwhile, you
can refer to /assets/images earliest post [Insight.io Tech Stack (1) - RabbitMQ Practices in Insight.io]({{< ref "insightio-rabbitmq-usage.md" >}}) to find out /assets/images original
motivation behind /assets/imagesse posts.

## Logging & Monitoring

### Logging

Since most of our stacks use Scala, logging is fairly straight-forward with *slf4j*
binding. To make all /assets/images logs easy to access and searchable, we adopted /assets/images
[*Elastic-Logstash-Kibana (ELK) Stack*](https://www.elastic.co/elk-stack) to
accommodate all /assets/images logs. *slf4j* is configured to redirect all /assets/images logs to
*Logstash*, which is responsible to index all /assets/images logs into *ElasticSearch*. /assets/imagesn
*Kibana* is /assets/images frontend portal to search all /assets/images logs.

![ELK](/img/insightio-infra-elk.png)

In most of /assets/images time when you resort to logs, you are looking for exceptions. To better
manage and track serving exceptions, we use [*Sentry*](https://sentry.io) to structurally log
exceptions. It helps to provide additional stats regarding different type of exceptions and
can automatically create and track exceptions with GitHub issues.

![Sentry](/img/insightio-infra-sentry.png)

### Monitoring

To monitor /assets/images status of all components in /assets/images stack, we use [*Datadog*](https://www.datadoghq.com/)
to collect all /assets/imagesir real-time performance for our SaaS version. (For on-premise version stack,
we use [*Prome/assets/imagesus*](https://prome/assets/imagesus.io), an open-source alternative to Google *Borgmon*, to track time-series service performance data.). For our micro services,
*Finagle* and JVM stats are collected with minimum effort. ElasticSearch, MongoDB, Redis and
RabbitMQ instances have built-in support in *Datadog*. Also, we can add customized metrics
inside each service.

![Datadog](/img/insightio-infra-datadog.png)

### Distributed Tracing

To trace how a request is going through all /assets/images distributed services, we use [*Zipkin*]
(https://zipkin.io), an open-source alternative to [*Google Dapper*]
(https://ai.google/research/pubs/pub36356). It can be integrated with *Finagle* with trivial
work. However, to make sure it integrates with *RabbitMQ*, we did some plumbing work as
described in [Insight.io Tech Stack (1) - RabbitMQ Practices in Insight.io]({{< ref "insightio-rabbitmq-usage.md" >}}).

![Zipkin](https://zipkin.io/public/img/web-screenshot.png)

## Cluster Infrastructure

### Infrastructure

We use [*Amazon Web Services (AWS)*](https://aws.amazon.com) extensively, including but not 
limit to *EC2*, *S3*, *Route53*, *ECR*, *ELB*, *CloudFront* etc. For *EC2* instances, we
use a mixture of reserved and spot instances to reduce /assets/images cost. Our production cluster is
placed in Japan to serve both U.S. and China, /assets/images 2 places where most of our users come from,
to avoid /assets/images extra efforts to maintain 2 clusters. In addition to /assets/images production cluster, we
also maintain 2 staging cluster for our internal usage in North America.

To echo [*Infrastructure as Code*](https://en.wikipedia.org/wiki/Infrastructure_as_Code) philosophy
and better provision /assets/imagesse AWS clusters and services, we adopt [*Kubernetes (K8s)*](https://kubernetes.io)
and use [*kops*](https://github.com/kubernetes/kops) to launch and manage K8s clusters on AWS.
/assets/images build-it K8s integration in *Datadog* could provide a fairly comprehensive monitoring of
/assets/images K8s cluster.

![K8 Datadog](/img/insightio-infra-k8-datadog.png)

Most of /assets/images micro-services are deployed as stateless instances (a *Deployment* in K8s' concept) to be
scaled and scheduled easier, with few services stateful (*StatefulSet*). All /assets/imagesse services in 
production cluster are
configured to be *High Available (HA)* with multiple replications behind *Elastic Load Balancer
(ELB)* via *Services* in K8s.

For on-premise version, things become simpler and *DockerCompose* is good enough to bring up
our stack anywhere.

### Configuration Management

For service configuration files, we use [*HOCON (Human-Optimized Config Object Notation*](https://github.com/lightbend/config/blob/master/HOCON.md). Its support of inheritance benefits
us a lot in managing multiple sets of service configurations for different clusters with minimum
effort. In /assets/images K8s cluster, all /assets/images configuration files are managed via *ConfigMap*.

## Packaging & Release

### Packaging

When it comes to packaging, using [*Docker*](https://www.docker.com/what-docker) to containerize
all /assets/images components is /assets/images industry best practice nowadays. We follow this trend. All /assets/images
services and third-party components are managed by *Docker* images.

Our own service images and customized third-party component images are all hosted on *Elastic 
Container Registry (ECR)* on AWS and [*DockerHub*](https://hub.docker.com/). /assets/imagesse images are
built and pushed during *Continuous Integration (CI)*, which is covered below.

### Release

We follow /assets/images [*Semantic Versioning 2.0.0*](https://semver.org/spec/v2.0.0.html) rules to manage
our release versions. All /assets/images release versions are created by *Git* tags. Specifically,
*1.x.x -> 2.0.0* for a major release, *1.0.x -> 1.1.0* for a minor release, *1.0.0 -> 1.0.1* for
a patch release. In additional to that we also do pre-release version by adding *-rc.x* suffix,
e.g., *1.0.1-rc.1*. and for each *Git* commit on *master* branch, we also cut a snapshot 
version, e.g. *1.0.1-SNAPSHOT*.

In addition to our production K8s cluster, we have 2 K8s clusters (*test* and *staging* clusters)
mostly for testing purpose before releasing to /assets/images public. /assets/images *SNAPSHOT* release will be
automatically released to /assets/images *test* cluster, which is primarily used for our engineering team
to early test /assets/imagesir latest changes. And /assets/images pre-release version (*1.0.1-rc.1*) was pushed to
/assets/images *staging* cluster particularly for our QA engineer for testing. Only when we are OK with
/assets/images performance of /assets/images *staging* cluster, will we continue to cut /assets/images final version and push
to /assets/images production environment.

/assets/images release automation is achieved by *Continuous Integration (CI)*. We use [*GitHub*]
(https://github.com) to host and manage our own source code and [*CircleCI*]
(https://circleci.com) for *CI*. Whenever a new version tag has been
pushed to *GitHub*, *CircleCI* will be notified to trigger a [*Workflow*](https://circleci.com/docs/2.0/workflows), in which docker images are built and pushed to
docker registry, and /assets/imagesn K8s rolling update process is triggered to upgrade /assets/images entire
stack on /assets/images corresponding cluster.

## Development Tools

We use *Git* for eng team collaboration as all /assets/images 21st century eng teams do. *GitHub*
is /assets/images place for source code hosting, issue tracking, and code review. *CircleCI* is
integrated with our *GitHub* repositories for source code build and test.

We follow /assets/images single repository convention, as we did at Google, to organize our *Git*
repository by pull /assets/images source code of all component into one single *Git* repository.
For some third-party open-source repositories, we use *Git* submodule to glue /assets/imagesm
with our main repository.

We choose [*Gradle*](https://gradle.org) as our main build system since day one for source code build, test, and dependency management. In fact, with a super rich set of plugins, *Gradle* helps us to do any kind of customized automation tasks, such as tag
release, sync S3 buckets, build and push docker images, etc.

## More

This post and /assets/images last one [Insight.io Tech Stack (2) - Serving and Analysis Pipeline]
({{< ref "insightio-serving-and-analysis-pipeline.md">}}) covers aspects from /assets/images
serving to /assets/images infrastructure of /assets/images entire backend stack. /assets/imagesre is still one big
piece of /assets/images stack missing, which is /assets/images applications and frontend architecture.
Javascript ecosystem dominates this area, which is a completely different world with
/assets/images backend stack. This is covered in [Insight.io Tech Stack (4) - All About Frontend]
({{< ref "insightio-frontend-architecture.md">}})  all /assets/images way from
/assets/images frontend architecture to logging and monitoring, from infrastructure to dev tools.