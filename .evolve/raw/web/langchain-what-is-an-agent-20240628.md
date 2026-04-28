---
title: "What is an AI agent?"
source_url: "https://blog.langchain.dev/what-is-an-agent/"
authors: ["Harrison Chase"]
publisher: "LangChain Blog"
date_published: "2024-06-28"
date_fetched: "2026-04-28"
evidence_type: "url"
language: "en"
topics: ["agent definition", "agentic spectrum", "orchestration", "observability", "evaluation"]
---

# What is an AI agent?

Harrison Chase
June 28, 2024

"What is an agent?"

I get asked this question almost daily. At LangChain, we build tools to help developers build LLM applications, especially those that act as a reasoning engines and interact with external sources of data and computation. This includes systems that are commonly referred to as "agents".

Everyone seems to have a slightly different definition of what an AI agent is. My definition is perhaps more technical than most:

> An AI agent is a system that uses an LLM to decide the control flow of an application.

Even here, I'll admit that my definition is not perfect. People often think of agents as advanced, autonomous, and human-like -- but what about a simple system where an LLM routes between two different paths? This fits my technical definition, but not the common perception of what an agent should be capable of. It's hard to define exactly what an agent is!

That's why I really liked Andrew Ng's tweet last week. In it he suggests that "rather than arguing over which work to include or exclude as being a true AI agent, we can acknowledge that there are different degrees to which systems can be agentic." Just like autonomous vehicles, for example, have levels of autonomy, we can also view AI agent capabilities as a spectrum. I really agree with this viewpoint and I think Andrew expressed it nicely. In the future, when I get asked about what an agent is, I will instead turn the conversation to discuss what it means to be "agentic".

## What does it mean to be agentic?

I gave a TED talk last year about LLM systems and used the slide below to talk about the different levels of autonomy present in LLM applications.

A system is more "agentic" the more an LLM decides how the system can behave.

Using an LLM to route inputs into a particular downstream workflow has some small amount of "agentic" behavior. This would fall into the Router category in the above diagram.

If you do use multiple LLMs to do multiple routing steps? This would be somewhere between Router and State Machine.

If one of those steps is then determining whether to continue or finish - effectively allowing the system to run in a loop until finished? That would fall into State Machine.

If the system is building tools, remembering those, and then taking those in future steps? That is similar to what the Voyager paper implemented, and is incredibly agentic, falling into the higher Autonomous Agent category.

These definitions of "agentic" are still pretty technical. I prefer the more technical definition of "agentic" because I think it's useful when designing and describing LLM systems.

## Why is "agentic" a helpful concept?

As with all concepts, it's worth asking why we even need the concept of "agentic". What does it help with?

Having an idea of how agentic your system can guide your decision-making during the development process - including building it, running it, interacting with it, evaluating it, and even monitoring it.

The more agentic your system is, the more an orchestration framework will help. If you are designing a complex agentic system, having a framework with the right abstractions for thinking about these concepts can enable faster development. This framework should have first-class support for branching logic and cycles.

The more agentic your system is, the harder it is to run. It will be more and more complex, having some tasks that will take a long time to complete. This means you will want to run jobs as background runs. This also means you want durable execution to handle any errors that occur halfway through.

The more agentic your system is, the more you will want to interact with it while it's running. You'll want the ability to observe what is going on inside, since the exact steps taken may not be known ahead of time. You'll want the ability to modify the state or instructions of the agent at a particular point in time, to nudge it back on track if it's deviating from the intended path.

The more agentic your system is, the more you will want an evaluation framework built for these types of applications. You'll want to run evals multiple times, since there is compounding amount of randomness. You'll want the ability to test not only the final output but also the intermediate steps to test how efficient the agent is behaving.

The more agentic your system is, the more you will want a new type of monitoring framework. You'll want the ability to drill down into all the steps an agent takes. You'll also want the ability to query for runs based on steps an agent takes.

Understanding and leveraging the spectrum of agentic capabilities in your system can improve the efficiency and robustness of your development process.

## Agentic is new

One thing that I often think about is what is actually new in all this craze. Do we need new tooling and new infrastructure for the LLM applications people are building? Or will generic tools and infrastructure from pre-LLM days suffice?

To me, the more agentic your application is, the more critical it is to have new tooling and infrastructure. That's exactly what motivated us to build LangGraph, the agent orchestrator to help with building, running, and interacting with agents, and LangSmith, the testing and observability platform for LLM apps. As we move further on the agentic spectrum, the entire ecosystem of supportive tooling needs to be reimagined.
