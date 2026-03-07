# spec session

Build a product specification through conversation.

## Trigger

The user says something like:
- "I want to define a product"
- "Let's build a spec"
- "Help me scope out this system"
- "I have an idea for a service, help me specify it"
- "Let's write a specification"

## What to do

Read `system/ENTRYPOINT.md` in this plugin's directory and follow the session
start protocol. The entrypoint will:

1. Check if a project exists or needs bootstrapping
2. Orient you on the current state
3. Route you to the right stance based on what the human wants to do

The spec-builder uses two complementary models:

- **The Journey** (linear arc): Intake, Explore, Model, Reconcile, Structure, Draft, Review, Deliver. Guides overall progress.
- **The Stances** (operating modes): Understand, Organize, Produce, Validate. What you do moment-to-moment.

Follow the conversation. Adopt the right stance. Let the journey guide your
sense of overall progress. See ENTRYPOINT.md for full details.
