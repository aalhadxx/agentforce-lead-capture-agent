# Contributing to Agentforce Lead Capture Agent

First off, thank you for considering contributing to this open-source project! It's people like you that make the Salesforce community such a great place to learn, inspire, and create.

## Getting Started

1. **Fork the repository** and create your branch from `main`.
2. **Set up your environment**:
    * Make sure you have the [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) installed.
    * Authenticate to a sandbox or Developer Edition org (with Agentforce enabled).
    * Deploy the code: `sf project deploy start`.
3. **Assign the Permission Set**:
    * The Einstein Service Agent user needs the `LeadCaptureAgent_Apex_Access` permission set to successfully create Leads in `USER_MODE`.

## Testing Your Changes

* Use the `sf agent preview start`, `send`, and `end` commands to test your modifications to the Agent Script or Apex logic.
* Ensure you cover multi-turn scenarios (e.g., providing only one field first).
* Validate that no regression occurs with the Agentforce `leadId` output binding.

## Pull Request Process

1. Ensure your code aligns with the repository's coding standards.
2. Update the `README.md` or `CLAUDE.md` if your changes introduce new deployment steps or gotchas.
3. Submit a Pull Request targeting the `main` branch. 
4. Provide a detailed description of your changes, including any preview trace results demonstrating success.

## Reporting Issues

If you find a bug, please use the provided Issue Templates. Include:
* Your Salesforce CLI version
* A snippet of the preview trace showing the failure
* Steps to reproduce the issue

## Suggesting Enhancements

We welcome feature requests! Please submit an issue using the Feature Request template, explaining the "Why" behind the feature.
