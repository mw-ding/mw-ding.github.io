---
title: "Insight.io Tech Stack (4) - All About Frontend"
---

All the previous posts of this Insight.io Tech Stack Series ([1. Message Queue]({{< ref "insightio-rabbitmq-usage.md">}}),
[2. Serving & Pipeline]({{< ref "insightio-serving-and-analysis-pipeline.md">}}),
[3. DevOps & Infra]({{< ref "insightio-devops-infra.md">}})) talked about every aspect
of the backend system. Let's try a different flavor today by diving into our frontend
architecture, which is dominated by Javascript.

As elaborated in the [first post]({{< ref "insightio-rabbitmq-usage.md">}}), the intention
is to do some high-level summary of what we have done here at Insight.io in terms of tech
stack. I think this not only helps to showcase how we glue open source solutions together
into an online service but also as an opportunity to retrospect what we can do better
in the future.

## Product Overview

Frontend acts as the direct exposure of our services to our end users. Before running into
any details of its architecture, it might be helpful to go through our entire product line
for the sake of understanding the technical challenges we are dealing with.

### Code Browsing/Search

![Code Search](/assets/images/insightio-frontend-product-code-search.png)

Our first product is an online code browsing and search application. Turbo-charged by our
featured code intelligence engine, our application builds a huge source code reference graph
among all the open source projects included in our system. With that, you can find how an API
function is used in different places with just one click, which helps developers to locate
code online much faster without even opening your heavy weighted IDE. Also, by understanding
the structural relationships of source code files, we rank search results better to help
developers to search code faster than doing a `grep`.

### Code Review

![Code Review](/assets/images/insightio-frontend-product-code-review.png)

If code browsing and search features do not sound promising enough to you, our code review with
code intelligence product will definitely save you a ton of time. As one of the critical steps
of software development process, code review takes a big chunk of time in an established tech
company, mostly because you have to copy/paste code around and switch between your IDE and code review tools trying to find and understand the entire
context of the code changes. With our code intelligence armed, you can locate the exact source
code with the full context of the code changes just one click away. This is going to be another
efficiency booster to your valuable development process.

### Browser Extensions

![Browser Extension](/assets/images/insightio-frontend-product-browser-extension.png)

Developers use GitHub (or GitLab/BitBucket) to host and browse their source code in most of the
time. Without breaking their conventions, we also built a browser extension product *Insight.io
for GitHub*, bringing our intelligent code browsing experience seamlessly to GitHub itself. It's
available for [Chrome](https://chrome.google.com/webstore/detail/insightio-for-github/pmhfgjjhhomfplgmbalncpcohgeijonh?hl=en-US),
[Firefox](https://addons.mozilla.org/en-US/firefox/addon/insight-io-for-github/), and Safari. For
our enterprise stack, we also derive similar products for GitLab and BitBucket enterprise
versions. This product has been featured as the [**#3 Product of the Day**](https://www.producthunt.com/posts/insight-io-for-github) on [ProductHunt](https://www.producthunt.com).

In short, as a startup which needs to be adaptive to varies kinds of customer feature requests,
we have to design and build a frontend architecture elastic enough to serve multiple products
running in different environments and flexible to be extended for future new products. And in
the meanwhile, it has to be both user and development friendly.

## Background

In the very early day when this was still a toy project, without too much frontend development
experiences, we built the first prototype of the project with pure [*jQuery*](https://jquery.com) and
[*Bootstrap*](https://getbootstrap.com). There was very little MVC modularization in the code. Data fetching,
handling, and view rendering logics were intertwined together in one single source file. As you can
imagine, soon as the complexity of the user interaction increases, things went out of control, because
we spent too much time on figuring out the actual problem in a massive chunk of code for even a tiny
bug fix. It was depressing but also motivating to find the correct solutions like we did for the backend
since obviously, we haven't done things right.

It was the time when [*React*](https://reactjs.org/) and [*Flux*](https://facebook.github.io/flux/) started to
gain a lot of attention and naturally they became the major candidates on our plate. Particularly, Jing's
talk [*Rethinking Web App Development at Facebook*](https://youtu.be/nYkdrAPrdcw) on *F8* conference was
very inspiring and pinpointed the exact problem in our case. And started from there, we decided to fully
embrace *React* and *Flux*. Very soon, as we followed the single flow programming pattern of *Flux*, the
structure of our frontend code has never been that clean and organized.

As always, as we keep growing, some drawbacks of the *Flux* architecture became irritating, like too many
redundant codes (e.g. actions), decentralized state management, etc.. We kept diagnosing the essences of these
issues and actively looking for best practices from the fast-growing *React* community. The entire frontend
architecture became much more mature and stable along the way after a lot of iterations, as long as we believe
in doing the right thing.

## Architecture

We use *React*, period.

### Programming Language

<img src='https://d33wubrfki0l68.cloudfront.net/f35d49d959deb5bfd7deb80c2668128367e2917c/a8232/assets/images/babel-black.svg' height='60' alt='Babel' />

Thanks to [*Babel*](https://babeljs.io/) that we can use *Ecmascript 6 (ES6)* to build our applications.
*ES6* provided a lot of modern programming language features (e.g. arrow functions, template literals,
destructuring, class, generator, etc.) very close to *Scala* as of backend development, thus providing a very unified
programming experience in the entire stack.

### Model

<img src='https://camo.githubusercontent.com/f28b5bc7822f1b7bb28a96d8d09e7d79169248fc/687474703a2f2f692e696d6775722e636f6d2f4a65567164514d2e706e67' height='60' alt='Redux' />

We later use [*Redux*](https://redux.js.org/) to replace *Flux* as our core data model management framework. The
[*Three Principles*](https://redux.js.org/introduction/three-principles) are quite self-explanatory to the
reasons we choose it:

1. Single source of truth
2. State is read-only
3. Changes are made with pure functions

To echo the second principle, we adopt [*Immutable.js*](https://facebook.github.io/immutable-js/) to protect the
read-only global state.

<img src='https://redux-saga.js.org/logo/0800/Redux-Saga-Logo-Landscape.png' height='60' alt='Redux Saga' />

[*Redux-Saga*](https://redux-saga.js.org/) is the framework we use for managing remote asynchronous data exchanging.
Its innovative way of using *generator* in *ES6* make asynchronous flows look like standard synchronous code, which
hugely improves the beauty of the code. Thus it stands out from other candidates like [*Redux Thunk*](https://github.com/reduxjs/redux-thunk).

For some real-time sensitive data exchanges use cases, we use *WebSockets* to adopt data pushing instead of just 
pulling.

### Controller

<img src="https://www.hkinfosoft.com/wp-content/uploads/2018/03/Dynamic-transitions-with-react-router-and-react-transition-group-200-min.png" height='100' alt='React Router' />

For component routing control, [*React Router*](https://reacttraining.com/react-router/) is the default choice for
*React* based applications. To make sure the routing params can be accessed from *Redux*, we did some plumbing work
ourselves to make it real, since it's a *React* library not designed particularly for *Redux*.

### View

One of the standards in *React* community nowadays is importing CSS files into Javascript as modules, so that
frontend source codes can be managed by a single module system. There
are a couple of such libraries can do so. We use [*PostCSS*](https://postcss.org/) and its *Webpack* loader
to achieve this.

For other static files, like fonts, images, we also use *Webpack* loaders so that they can be accessed directly
from the Javascript source code.

## Performance Tuning

In most of the time, *React* performs well in terms of rendering latency. Occasionally, we
encountered performance issues with *React* and that's when performance tuning is unavoidable.

One example is rendering the file diff view in our code review product. There could be a huge
amount of very tiny *React* components in a single file diff view, particularly when the source
file is large, because for each token (e.g. functions, variables, keywords, etc.) is a single
component, and it could also be wrapped by syntax highlight, hovering highlighting and code
intelligence decoration components.

![File Diff View Before](/assets/images/insightio-frontend-performance-1.png)

![File Diff View Before Performance](/assets/images/insightio-frontend-performance-analysis-1.png)

This big amount of components could result in a very large chunk of *Scripting* latency in
the browser. This deteriorates the user experience a lot, particularly when there are a lot of
file diff views in a code review (which is very common). User's browser would freeze for a
very long time and sometimes even crashes.

To solve this issue, we move the file diff view rendering from client/browser side to server
side as APIs. The entire file diff view is rendered in the server and returned as pure HTML.
Now *React* does not need to deal with any DOM computation which reduces a huge amount of
*Scripting* time. This server-side rendering solution immediately solves the user experience
issue that the browser won't freeze any more.

![File Diff View After](/assets/images/insightio-frontend-performance-2.png)

![File Diff View After Performance](/assets/images/insightio-frontend-performance-analysis-2.png)

One downside of this solution is that the file
diff views HTML won't be included into *React*'s virtual DOM hierarchy and cannot be managed by
*React*. But thanks to [*React Portals*](https://reactjs.org/docs/portals.html) introduced
since *React Fiber (16)*, we can still render and manipulate children components in this pure
HTML DOM node.

## Monitoring & Tracking

We use [*Google Analytics*](https://analytics.google.com/analytics/web) to do some high level
user behavior and traffic tracking, use [*Inspectlet*](https://www.inspectlet.com/) to sample
user's real behavior playbacks. What we rely on the most is actually custom event tracking on
[*Mixpanel*](https://mixpanel.com/), including but not limited to:

* Event Segmentations

![Mixpanel 1](/assets/images/insightio-frontend-tracking-mixpanel-1.png)

* Funnel Analysis

![Mixpanel 2](/assets/images/insightio-frontend-tracking-mixpanel-2.png)

* Retention Analysis

![Mixpanel 3](/assets/images/insightio-frontend-tracking-mixpanel-3.png)

To redirect all the custom events into *Mixpanel*, we implemented a light weighted *React*
wrapper as a framework to intercept user actions and transform into events. By default, it
has a *Mixpanel* adapter which commits events to *Mixpanel*. For enterprise version, we can
plugin a *Logstash* adapter to redirect events to *Elasticsearch*.

## Dev Tools

We use [*Yarn*](https://yarnpkg.com/en/) to manage our javascript dependencies and define build
tasks. To follow our own convention of using *Gradle* to manage build tasks, we use [*gradle-node-plugin*](https://github.com/srs/gradle-node-plugin) to trigger *Yarn* tasks with
*Gradle*.

<img src="https://cdn-images-1.medium.com/max/1600/1*gdoQ1_5OID90wf1eLTFvWw.png" height='100' alt='Webpack' />

For bundling and packaging Javascript, CSS, image and font files, we heavily rely on
[*Webpack*](https://webpack.js.org/). With various resource loaders, we decompose our
applications into a lot of separate modules. This helps to relieve the pain to manage different
frontend resources. Also, its dev server facilitates our frontend development process by its
featured live reloading, so that your local changes can be applied instantaneously without manually reload your frontend application.

For *React* application, we heavily rely on [*React Developer Tools*](https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi?hl=en)
and [*Redux Dev Tools*](https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd?hl=en) Chrome extensions. Particularly, the ability of *Redux Dev Tools* plugin to jump to
arbitrary application helps the debugging a lot.

![Redux Dev Tools](/assets/images/insightio-frontend-redux-dev-tools.png)

In a lot of cases when doing purely frontend development, we only touch Javascript source codes.
It would be burdensome to start then entire backend stack to verify some functionalities and it
would be helpful just reusing some existing stacks. In our case, we have a long-running *test*
and *staging* stack on our *K8s* cluster, particularly for regression tests. Thus, I built a
quick Chrome extension, which, when enabled, always redirects the actual Javascript and CSS 
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
technologies evolve so fast that we don't really have that much bandwidth to achieve this goal 100%. A 
couple of examples would be that we have always wanted to do are switching to *Typescript* to better 
integrate with *Thrift* data structure definitions, using [*GraphQL*](https://graphql.org/) to improve 
our data model management, etc..

From a positive point of view, it's always good to retrospect and identify some aspects that we can do
better. That is when growth and learning are happening. In the future, when we have the chances to do
it again, we can definitely do it in a better way.