---
title: "Insight.io Tech Stack (4) - Frontend Architecture"
date: 2018-06-15T23:56:17-07:00
draft: true
---

All the previous posts of this Insight.io Tech Stack Series ([1. Message Queue]({{< ref "insightio-rabbitmq-usage.md">}}),
[2. Serving & Pipeline]({{< ref "insightio-serving-and-analysis-pipeline.md">}}),
[3. DevOps & Infra]({{< ref "insightio-devops-infra.md">}})) talked about every aspects
of the backend system. Let's try a different flavor today by diving into our frontend
architecture, which is dominated by Javascript.

As elaborated in the [first post]({{< ref "insightio-rabbitmq-usage.md">}}), the intention
is to do some high level summary of what we have done here at Insight.io in terms of tech
stack. I think this not only helps to showcase how we glue open source solutions together
into an online service, but also as an opportunity to retrospect of what we can do better
in the future.

## Product Overview

Frontend acts as the direct exposure of our services to our end users. Before running into
any details of its architecture, it might be helpful to go through our entire product line
for the sake of understanding the technical challenges we are dealing with.

### Code Browsing/Search

![Code Search](/img/insightio-frontend-product-code-search.png)

Our first product is an online code browsing and search application. Turbo-charged by our
featured code intelligence engine, our application build a huge source code reference graph
among all the open source projects included in our system. With that, you can find how an API
function is used in different places with just one click, which helps developers to locate
code online much faster without even opening your heavy weighted IDE. Also, by understanding
the structural relationships of source code files, we rank search results better to help
developers to search code faster than doing a `grep`.

### Code Review

![Code Review](/img/insightio-frontend-product-code-review.png)

If code browsing and search features do not sound promising enough to you, our code review with
code intelligence product will definitely save you a ton of time. As one of the critical steps
of software development process, code review takes a big chunk of time in an established tech
company, mostly because you have to copy/paste code around and swtich between your IDE and code review tools trying to find and understand the entire
context of the code changes. With our code intelligence armed, you can locate the exact source
code with the full context of the code changes just one click away. This is going to be another
efficiency booster to your valuable development process.

### Browser Extensions

![Browser Extension](/img/insightio-frontend-product-browser-extension.png)

Developers use GitHub (or GitLab/BitBucket) to host and browse their source code in most of the
time. Without breaking their conventions, we also built a browser extenion product *Insight.io
for GitHub*, bringing our intelligent code browsing experience seamlessly to GitHub itself. It's
available for [Chrome](https://chrome.google.com/webstore/detail/insightio-for-github/pmhfgjjhhomfplgmbalncpcohgeijonh?hl=en-US),
[Firefox](https://addons.mozilla.org/en-US/firefox/addon/insight-io-for-github/) and Safari. For
our enterprise stack, we also derive similar products for GitLab and BitBucket enterprise
versions. This product has been featured as the [**#3 Product of the Day**](https://www.producthunt.com/posts/insight-io-for-github) on [ProductHunt](https://www.producthunt.com).

In short, as a startup which needs to be adaptive to varies kinds of customer feature requests,
we have to design and build a frontend architecture elastic enough to serve multiple products
running in different environments and flexible to be extended for future new products. And in
the meanwhile, it has to be both user and developement friendly.

## Background


## Architecture

## Performance Tuning

In most of the time, *React* performes well in terms of rendering latency. Occasionally, we
encountered performance issues with *React* and that's when performance tuning is unavoidable.

One example is rendering the file diff view in our code review product. There could be a huge
amount of very tiny *React* components in a single file diff view, particularly when the source
file is large, because for each token (e.g. functions, variables, keywords, etc.) is a single
component, and it could also be wrapped by syntax highlight, hovering highlighting and code
intelligence decoration components.

![File Diff View Before](/img/insightio-frontend-performance-1.png)

![File Diff View Before Performance](/img/insightio-frontend-performance-analysis-1.png)

This big amount of components could result in a very large chunk of *Scripting* latency in
browser. This deteriorates the user experience a lot, particularly when there are a lot of
file diff views in a code review (which is very common). User's browser would freeze for a
very long time and sometimes even crashes.

To solve this issue, we move the file diff view rendering from client/browser side to server
side as APIs. The entire file diff view is rendered in the server and returned as pure HTML.
Now *React* does not need to deal with any DOM computation which reduces a huge amount of
*Scripting* time. This server side rendering solution immediately solves the user experience
issue that the browse won't freeze any longer. 

![File Diff View After](/img/insightio-frontend-performance-2.png)

![File Diff View After Performance](/img/insightio-frontend-performance-analysis-2.png)

One downside of this solution is that the file
diff view HTML won't be included into *React*'s virtual DOM hierarchy and cannot be managed by
*React*. But thanks to [*React Portals*](https://reactjs.org/docs/portals.html) introduced
since *React Fiber (16)*, we can still render and manipulate children components in this pure
HTML DOM node.

## Monitoring & Tracking

We use [*Google Analytics*](https://analytics.google.com/analytics/web) to do some high level
user behavior and traffic tracking, use [*Inspectlet*](https://www.inspectlet.com/) to sample
user's real behavior playbacks. What we rely on the most is actually custom event tracking on
[*Mixpanel*](https://mixpanel.com/), including but not limited to:

* Event Segmentations

![Mixpanel 1](/img/insightio-frontend-tracking-mixpanel-1.png)

* Funnel Analysis

![Mixpanel 2](/img/insightio-frontend-tracking-mixpanel-2.png)

* Retention Analysis

![Mixpanel 3](/img/insightio-frontend-tracking-mixpanel-3.png)

To redirect all the custom events into *Mixpanel*, we implemented a light weighted *React*
wrapper as a framework to intercept user actions and transform to events. By default, it
has a *Mixpanel* adapter which commits events to *Mixpanel*. For enterprise version, we can
plugin a *Logstash* adapter to redirect events to *Elasticsearch*.

## Dev Tools

We use [*Yarn*](https://yarnpkg.com/en/) to manage our javascript dependencies and define build
tasks. To follow our own convention of using *Gradle* to manage build tasks, we use [*gradle-node-plugin*](https://github.com/srs/gradle-node-plugin) to trigger *Yarn* tasks with
*Gradle*.

For bundling and packaging javascript, css, image and font files, we heavily rely on
[*Webpack*](https://webpack.js.org/). With various resource loaders, we decompose our
applications into a lot of seperate modules. This helps to relieve the pain to manage different
frontend resources. Also, its dev server facilitates our frontend development process by its
featured live reloading, so that your local changes can be applied instantanously without manually reload your frontend application.

In a lot of cases when doing purely frontend development, we only touch Javascript source codes.
It would be burdensome to start then entire backend stack for verify some functionalities and it
would be helpful just reusing some existing stacks. In our case, we have a long running *test*
and *staging* stack on our *K8s* cluster, particularly for regression tests. Thus, I built a
quick Chrome extension, which, when enabled, always redirects the actual javascript and css 
bundle asset files on *test* and *staging* stack to our local webpack dev server, which 
contains the latest changes on the local dev machine.

The implementation is quite straight-forward, just leveraging the chrome API
(`chrome.webRequest.onBeforeRequest.addListener`) to intercept the web requests to fetch all 
the javascript and css files before it has been sent and simply return a redirection result to
the corresponding urls on the local webpack dev server.

```
chrome.webRequest.onBeforeRequest.addListener(
  (info) => {
    const assetRegex = /https?:\/\/[^/]+\/assets\/dist\/codatlas\/[0-9a-f]*-(.*)\.(css|js)/;
    const m = info.url.match(assetRegex);
    if (interceptorOn && !!m) {
      const name = m[1];
      const ext = m[2];
      const destUrl = `http://localhost:9090/assets/dist/codatlas/${name}.${ext}`;
      console.log(`Redirect ${info.url} to ${destUrl}`);
      return {
        redirectUrl: destUrl
      };
    }
    return null;
  },
  // filters
  {
    urls: [
      'http://test.insight.io/assets/dist/*',
      'https://staging.insight.io/assets/dist/*'
    ],
    types: ['script']
  },
  // Handle the call back synchronously.
  ['blocking']
);
```

## Conclusion and The Future

We are trying our best to apply the state-of-art frontend best practices, frameworks and libraries into
our frontend architecture to reach the best user and development experience. However, the frontend
technologies evolve so fast that we don't really have that much of bandwidth to achieve this goal. A 
couple of examples would be that we have always wanted to do are switching to *Typescript* to better 
integrate with *Thrift* data structure definitions, using [*GraphQL*](https://graphql.org/) to improve 
our data model management, etc..

In a positive point of view, it's always good to retrospect and identify some aspects that we can do
better. That is when growth and learning are happening. In the future, when we have the chances to do
it again, we can definitely do it in a better way.