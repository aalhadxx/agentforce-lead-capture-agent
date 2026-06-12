# Generic Agentforce Lead Capture Agent

An open-source, generic Salesforce Agentforce Service Agent template that handles conversational lead capture (collecting `LastName` and `Company`) and creates standard Lead records securely in User Mode using Apex.

## Overview

This repository provides:
1. **Agent Definition (`LeadCaptureAgent.agent`)**: The conversational instructions and configuration for the agent, binding input variables (`last_name`, `company`) and routing user turns to the custom subagent.
2. **Invocable Apex Action (`LeadCaptureTurnAction`)**: An intelligent input-parsing class that matches regular expressions to pull `LastName` and `Company` from the user message, asks the user for missing fields, and inserts the Lead in User Mode once all information is gathered.
3. **Invocable Apex Action (`LeadCreationAction`)**: A backup minimal Lead creator.
4. **Access Control (`LeadCaptureAgent_Apex_Access`)**: A permission set configured to grant the Einstein agent user create/read access to the Lead object and execute permission on the invocable classes.

## Getting Started

### 1. Deploy Metadata
Deploy the Apex classes, permission set, and agent bundle to your target Salesforce developer or sandbox org:
```bash
sf project deploy start
```

### 2. Configure Permissions
Assign the deployed `LeadCaptureAgent_Apex_Access` permission set to the Einstein Service Agent User:
1. Go to **Setup** > **Users** > **Permission Sets**.
2. Click **LeadCaptureAgent Apex Access**.
3. Select **Manage Assignments** and assign it to your Einstein Service Agent user.

### 3. Activate the Agent
Open the **Agent Builder** in your Salesforce org, navigate to **Lead Capture Agent**, review the topics, and click **Publish** and **Activate**.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
