---
description: Create and modify architecture diagrams in Draw.io format with Google Cloud Platform components. Generates professional .drawio files with GCP icons, proper styling, and common patterns.
triggers:
  - drawio
  - draw.io
  - architecture diagram
  - gcp diagram
  - create diagram
  - modify diagram
  - update diagram
---

# GCP Architecture Diagram Generator

Generate Draw.io architecture diagrams (`.drawio`) for GCP infrastructure following project conventions.

## Overview

This skill defines the standard component template and design rules for creating GCP architecture diagrams using draw.io.

## Component Template

### Base Component Structure

Each GCP component consists of two mxCell elements: a container (parent) and an icon with label (child).

```xml
<!-- Container (parent) -->
<mxCell id="XXXX" style="fillColor=#ffffff;strokeColor=#dddddd;shadow=1;strokeWidth=1;rounded=1;absoluteArcSize=1;arcSize=2;" value="" vertex="1">
  <mxGeometry height="60" width="{dynamic}" x="0" y="0" as="geometry" />
</mxCell>

<!-- Icon with label (child) - Use colors from "Icon Colors by Category" table -->
<mxCell id="" parent="XXXX" style="editableCssRules=.*;html=1;fontColor=#999999;;shape=mxgraph.gcp2.{shape};verticalLabelPosition=middle;verticalAlign=middle;labelPosition=right;align=left;spacingLeft=20;fillColor={category_fill};strokeColor={category_stroke};" value="&lt;font color=&quot;#000000&quot;&gt;{resource_name}&lt;/font&gt;&lt;br&gt;{resource_type}" vertex="1">
  <mxGeometry height="30" relative="1" width="30" as="geometry">
    <mxPoint x="15" y="15" as="offset" />
  </mxGeometry>
</mxCell>
```

### Template Parameters

| Parameter | Description |
|-----------|-------------|
| `{shape}` | GCP2 shape name from the "Available GCP2 Shapes" section |
| `{resource_name}` | Display name of the resource - **Must match the Terraform resource name** |
| `{resource_type}` | Type of the resource (e.g., `Cloud Run`) |
| `{dynamic}` | Width calculated based on label length |
| `{category_fill}` | Fill color from "Icon Colors by Category" (e.g., `#4285F4` for Compute) |
| `{category_stroke}` | Stroke color from "Icon Colors by Category" (e.g., `#1967D2` for Compute) |

### Resource Naming Convention

**IMPORTANT**: The `{resource_name}` must match the actual Terraform resource name to maintain consistency between infrastructure code and diagrams.

```hcl
# Terraform
resource "google_pubsub_topic" "event_topic" {
  name = "${local.resource_prefix}-events"  # → Use "events" or full name in diagram
}

resource "google_cloud_run_v2_service" "event_handler" {
  name = "${local.resource_prefix}-handler"  # → Use "event-handler" in diagram
}
```

When reading Terraform code:
1. Check the `name` attribute in resource definitions
2. Use the base name (without `resource_prefix`) for the diagram label
3. For resources with `${local.resource_prefix}-xxx` pattern, use `xxx` as the display name

### Style Properties

**Container:**
- White background (`fillColor=#ffffff`)
- Light gray border (`strokeColor=#dddddd`)
- Drop shadow enabled
- Rounded corners (`arcSize=2`)

**Icon:**
- Fill and stroke colors based on service category (see Icon Colors by Category)
- Label positioned to the right of the icon
- Two-line label format: resource name (black) + resource type (gray)

## Icon Colors by Category

Use GCP's official brand colors for each service category. Apply `fillColor` and `strokeColor` to the icon element.

| Category | Fill Color | Stroke Color | Hex Codes |
|----------|-----------|--------------|-----------|
| **Compute** | Google Blue | Dark Blue | `fillColor=#4285F4;strokeColor=#1967D2` |
| **Storage & Database** | Google Blue | Dark Blue | `fillColor=#4285F4;strokeColor=#1967D2` |
| **Networking** | Purple | Dark Purple | `fillColor=#7B1FA2;strokeColor=#4A148C` |
| **Data Analytics** | Magenta/Pink | Dark Pink | `fillColor=#E91E63;strokeColor=#AD1457` |
| **AI & Machine Learning** | Orange | Dark Orange | `fillColor=#FF9800;strokeColor=#E65100` |
| **Messaging & Integration** | Google Blue | Dark Blue | `fillColor=#4285F4;strokeColor=#1967D2` |
| **Security & Identity** | Google Yellow | Dark Yellow | `fillColor=#FBBC04;strokeColor=#E37400` |
| **Management & Monitoring** | Google Green | Dark Green | `fillColor=#34A853;strokeColor=#1E8E3E` |
| **Containers & Kubernetes** | Google Blue | Dark Blue | `fillColor=#4285F4;strokeColor=#1967D2` |
| **Developer Tools** | Gray | Dark Gray | `fillColor=#5F6368;strokeColor=#3C4043` |
| **Other Services** | Google Blue | Dark Blue | `fillColor=#4285F4;strokeColor=#1967D2` |
| **Icons & Symbols** | Gray | Dark Gray | `fillColor=#9AA0A6;strokeColor=#5F6368` |
| **Error/DLQ** | Google Red | Dark Red | `fillColor=#EA4335;strokeColor=#C5221F` |
| **External/User** | Light Blue | Blue | `fillColor=#4285F4;strokeColor=#1967D2` |

### Color Usage Examples

```xml
<!-- Compute: Cloud Run (Blue) -->
<mxCell style="...fillColor=#4285F4;strokeColor=#1967D2;..." />

<!-- Security: IAM (Yellow) -->
<mxCell style="...fillColor=#FBBC04;strokeColor=#E37400;..." />

<!-- Monitoring: Cloud Monitoring (Green) -->
<mxCell style="...fillColor=#34A853;strokeColor=#1E8E3E;..." />

<!-- Error Flow: Dead Letter Queue (Red) -->
<mxCell style="...fillColor=#EA4335;strokeColor=#C5221F;..." />
```

### Connector Colors

Match connector colors to the flow type:

| Flow Type | Color | Style |
|-----------|-------|-------|
| Normal data flow | `#4285F4` (Blue) | Solid |
| Error/DLQ flow | `#EA4335` (Red) | Dashed |
| Observability flow | `#34A853` (Green) | Solid or Dashed |
| IAM/Auth flow | `#FBBC04` (Yellow) | Dashed |

## Design Rules

- **No overlapping**: Arrange components and connectors without overlap
- **Uniform sizing**: Keep component sizes consistent throughout the diagram
- **Full names**: Use complete official resource names, not abbreviations
- **Consistent colors**: Use the "Icon Colors by Category" table above. Apply category-specific colors to all icons
- **Label margin**: Add right padding (15-20px) to container width. Base width on the longer of `resource_name` or `resource_type`
- **Orthogonal arrows**: Use only horizontal, vertical, or L-shaped (right-angle) connectors. Diagonal lines are not allowed

### Connector Priority Rules

**IMPORTANT**: Prioritize straight lines over L-shaped connectors for cleaner diagrams.

**Priority order:**
1. **Straight horizontal line** - Best choice when source and target are in the same row
2. **Straight vertical line** - Best choice when source and target are in the same column
3. **L-shaped (single bend)** - Use only when straight line is not possible
4. **Multiple bends** - Avoid; redesign layout if needed

**Forcing straight lines with explicit entry/exit points:**

To ensure straight lines, use explicit `exitX`, `exitY`, `entryX`, `entryY` attributes instead of `edgeStyle=orthogonalEdgeStyle`:

```xml
<!-- Horizontal straight line (right to left) -->
<mxCell style="html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;..." />

<!-- Vertical straight line (top to bottom) -->
<mxCell style="html=1;exitX=0.5;exitY=1;exitDx=0;exitDy=0;entryX=0.5;entryY=0;entryDx=0;entryDy=0;..." />
```

| Direction | Exit Point | Entry Point |
|-----------|------------|-------------|
| Horizontal (→) | `exitX=1;exitY=0.5` | `entryX=0;entryY=0.5` |
| Vertical (↓) | `exitX=0.5;exitY=1` | `entryX=0.5;entryY=0` |

**Layout strategy to maximize straight lines:**
- Arrange components so that connected items share the same row (Y) or column (X)
- Plan the grid layout before placing components
- Group related flows horizontally (e.g., main message flow left-to-right)
- Stack secondary flows vertically below the main flow

**Example - Good layout (straight lines):**
```
[Pub] ──→ [Topic] ──→ [Sub] ──→ [Run]   ← All horizontal (same Y)
                        │
                        ↓                 ← Vertical (same X)
                      [DLQ]
```

**Example - Poor layout (unnecessary bends):**
```
[Pub] ──→ [Topic]
              └──→ [Sub] ──→ [Run]      ← Avoid: L-shape not needed
```

### Connector Spacing Rules

**IMPORTANT**: Ensure adequate spacing between connected components for readability.

**Minimum spacing between arrow source and target:**

| Direction | Minimum Gap | Recommended Gap |
|-----------|-------------|-----------------|
| Horizontal (same row) | 80px | 100-120px |
| Vertical (same column) | 80px | 100-120px |
| L-shaped (between bends) | 60px | 80px |

**Gap calculation:**
- Gap = target_X - (source_X + source_width) for horizontal
- Gap = target_Y - (source_Y + source_height) for vertical

**Why adequate spacing matters:**
- Allows room for connector labels without overlap
- Improves visual clarity and readability
- Prevents cluttered appearance
- Makes arrows easier to follow

**Layout example with proper spacing:**
```
[Topic w=160]  ──100px──→  [Subscription w=280]  ──100px──→  [Cloud Run w=160]
x=40                        x=300                             x=680

Gap1 = 300 - (40+160) = 100px ✓
Gap2 = 680 - (300+280) = 100px ✓
```

**Common spacing mistakes to avoid:**
- Components too close (gap < 60px): arrows look cramped
- Inconsistent gaps: creates unbalanced appearance
- Labels overlapping arrows: increase gap or reposition

### Component Alignment Rules

**IMPORTANT**: Align components in a grid-like layout for visual consistency.

1. **Left-edge alignment**: Components in the same column must have the same X coordinate
2. **Top-edge alignment**: Components in the same row must have the same Y coordinate
3. **Consistent spacing**: Use uniform gaps between rows (100-120px) and columns (100-120px for connected components)
4. **Grid snapping**: Round all coordinates to multiples of 20px for clean alignment

**Layout Pattern:**

```
Row 1 (y=100):  [SA-1]           [SA-2]
                x=520            x=850

Row 2 (y=220):  [Pub] → [Topic] → [Sub] → [Run]
                x=40    x=280     x=520   x=850

Row 3 (y=380):                   [DLQ]   [Log]
                                 x=520   x=920

Row 4 (y=520):                   [DLQ-Sub] [Mon]
                                 x=520     x=920
```

**Alignment checklist:**
- [ ] All components in the same column share the same X coordinate
- [ ] All components in the same row share the same Y coordinate
- [ ] Row spacing is consistent (e.g., 120px between rows)
- [ ] Column spacing accommodates the widest component plus gap

### Container Width Calculation

Calculate the container width based on the **longer of `resource_name` or `resource_type`**:

```
max_label = max(len(resource_name), len(resource_type))
width = icon_width(30) + spacing_left(20) + max_label_width + right_margin(15)
```

**Width calculation formula:**
- Approximate character width: **7px per character** (for typical font)
- Base width: **65px** (icon + spacing + right margin)
- Formula: `65 + (max_label_chars × 7)`

**Recommended minimum widths by label length:**

| Longest Label | Character Count | Recommended Width |
|---------------|-----------------|-------------------|
| Short | ≤10 chars | 140px |
| Medium | 11-15 chars | 170px |
| Long | 16-20 chars | 200px |
| Very Long | 21-25 chars | 240px |
| Extra Long | >25 chars | 280px+ |

**Examples (comparing both labels):**
```
resource_name: "events" (6)
resource_type: "Cloud Pub/Sub" (13)  ← longer
→ 65 + (13 × 7) = 156 → round to 160px

resource_name: "events-dead-letter-subscription" (31)  ← longer
resource_type: "DLQ Subscription" (16)
→ 65 + (31 × 7) = 282 → round to 280px
```

**IMPORTANT**: Always round up to the nearest 20px increment.

## Available GCP2 Shapes

### Compute

- `app_engine`, `app_engine_icon`
- `cloud_functions`
- `cloud_run`
- `compute_engine`, `compute_engine_2`, `compute_engine_icon`
- `container_engine`, `container_engine_icon`
- `gke_on_prem`
- `gpu`

### Storage & Database

- `bigquery`, `big_query`
- `bucket`, `bucket_scale`
- `cloud_bigtable`
- `cloud_datastore`
- `cloud_filestore`
- `cloud_firestore`
- `cloud_memorystore`
- `cloud_spanner`
- `cloud_sql`
- `cloud_storage`
- `database`, `database_2`, `database_3`
- `persistent_disk`, `persistent_disk_snapshot`
- `storage`

### Networking

- `cloud_armor`
- `cloud_cdn`
- `cloud_dns`
- `cloud_external_ip_addresses`
- `cloud_firewall_rules`
- `cloud_load_balancing`
- `cloud_nat`
- `cloud_network`
- `cloud_router`
- `cloud_routes`
- `cloud_vpn`
- `dedicated_interconnect`
- `https_load_balancer`
- `load_balancing`
- `network`, `network_load_balancer`
- `partner_interconnect`
- `premium_network_tier`, `standard_network_tier`
- `traffic_director`
- `virtual_private_cloud`
- `vpn`, `vpn_gateway`

### Data Analytics

- `cloud_composer`
- `cloud_data_catalog`
- `cloud_data_fusion`
- `cloud_dataflow`, `cloud_dataflow_icon`
- `cloud_datalab`
- `cloud_dataprep`
- `cloud_dataproc`, `cloud_dataproc_icon`
- `data_studio`
- `genomics`

### AI & Machine Learning

- `ai_hub`
- `automl_natural_language`, `automl_tables`, `automl_translation`, `automl_video_intelligence`, `automl_vision`
- `cloud_automl`
- `cloud_inference_api`
- `cloud_jobs_api`
- `cloud_machine_learning`
- `cloud_natural_language_api`
- `cloud_speech_api`
- `cloud_text_to_speech`
- `cloud_translation_api`
- `cloud_video_intelligence_api`
- `cloud_vision_api`
- `dialogflow_enterprise_edition`
- `recommendations_ai`
- `tensorflow_lockup`, `tensorflow_logo`

### Messaging & Integration

- `cloud_endpoints`
- `cloud_iot_core`, `cloud_iot_edge`
- `cloud_pubsub`, `cloud_sub_pub`
- `cloud_scheduler`
- `cloud_tasks`
- `task_queues`, `task_queues_2`

### Security & Identity

- `beyondcorp`
- `cloud_iam`
- `cloud_security`
- `cloud_security_command_center`
- `cloud_security_scanner`
- `data_loss_prevention_api`
- `identity_aware_proxy`
- `key`, `key_management_service`
- `lock`
- `security_key_enforcement`

### Management & Monitoring

- `cloud_apis`
- `cloud_deployment_manager`
- `cloud_monitoring`
- `debugger`
- `error_reporting`
- `logging`
- `logs_api`
- `profiler`
- `stackdriver`
- `trace`

### Containers & Kubernetes

- `container_builder`
- `container_optimized_os`
- `container_registry`
- `kubernetes_logo`, `kubernetes_name`
- `istio_logo`
- `cloud_service_mesh`

### Developer Tools

- `cloud_code`
- `cloud_test_lab`
- `cloud_tools_for_powershell`
- `repository`, `repository_2`, `repository_3`, `repository_primary`

### Other Services

- `admob`
- `apigee_api_platform`, `apigee_sense`
- `firebase`
- `google_cloud_platform`, `google_cloud_platform_lockup`
- `maps_api`
- `transfer_appliance`

### Icons & Symbols

- `anomaly_detection`
- `arrow_cycle`, `arrows_system`
- `beacon`
- `blank`
- `check`, `check_2`, `check_available`, `check_scale`
- `clock`, `time_clock`
- `cloud`, `cloud_checkmark`, `cloud_computer`, `cloud_information`, `cloud_server`, `half_cloud`, `legacy_cloud`, `legacy_cloud_2`
- `cluster`
- `connected`, `internet_connection`
- `cost`, `cost_arrows`, `cost_savings`
- `desktop`, `desktop_and_mobile`
- `files`, `folders`
- `gateway`, `gateway_icon`
- `gear`, `gear_arrow`, `gear_chain`, `gear_load`
- `globe_world`
- `laptop`
- `lifecycle`
- `lightbulb`
- `list`, `view_list`
- `loading`, `loading_2`, `loading_3`
- `mobile_devices`
- `monitor`, `monitor_2`
- `node`
- `phone`, `phone_android`
- `placeholder`
- `process`
- `report`
- `safety`
- `save`
- `scale`
- `search`
- `servers_stacked`
- `service`, `service_discovery`
- `speed`
- `stream`
- `users`
- `visibility`
- `webcam`
- `website`

### Modifiers

- `modifiers_autoscaling`
- `modifiers_custom_virtual_machine`
- `modifiers_high_cpu_machine`
- `modifiers_high_memory_machine`
- `modifiers_preemptable_vm`
- `modifiers_shared_core_machine_f1`
- `modifiers_shared_core_machine_g1`
- `modifiers_standard_machine`
- `modifiers_storage`

## Instructions

1. **Read the Terraform code first**:
   - Read `main.tf` to understand module structure and dependencies
   - Check each module's resource files (e.g., `pubsub.tf`, `cloudrun.tf`) for actual resource names
   - Extract the `name` attribute values to use as `{resource_name}` in the diagram

2. **Analyze the target architecture**:
   - Identify GCP services used (Cloud Run, Pub/Sub, etc.)
   - Map data flow between components
   - Identify monitoring and observability components

3. **Create the diagram structure**:
   ```xml
   <mxfile host="app.diagrams.net">
     <diagram id="unique-id" name="Architecture Name">
       <mxGraphModel>
         <root>
           <mxCell id="0" />
           <mxCell id="1" parent="0" />
           <!-- Components here -->
         </root>
       </mxGraphModel>
     </diagram>
   </mxfile>
   ```

4. **Add GCP components**:
   - Use the component template with appropriate `{shape}` from the list
   - Set `{resource_name}` to match Terraform resource names (see "Resource Naming Convention")
   - Apply category-specific colors from "Icon Colors by Category"
   - Calculate container width based on label length

5. **Add connectors**:
   - Use orthogonal (right-angle) arrows only
   - Add labels to describe data flow
   - Use dashed lines for optional/error paths
   - Match connector colors to flow type (see "Connector Colors")

6. **File Location**: `docs/<pattern>/architecture-diagram.drawio`

## Key Points

- **Resource names must match Terraform** - Always read Terraform code first and use actual resource names
- Use `command = plan` style verification by opening in draw.io
- Each diagram should be self-contained with all required components
- Follow the two-line label format: resource name + resource type
- Apply category-specific colors consistently (see "Icon Colors by Category")
- Keep consistent spacing between components (100-120px between connected components)
- Group related components visually (e.g., all Pub/Sub resources together)
- Add a legend for complex diagrams
