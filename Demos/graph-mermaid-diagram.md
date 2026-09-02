```mermaid
---
config:
  layout: elk
  elk:
    mergeEdges: true
    nodePlacementStrategy: NETWORK_SIMPLEX
    nodePlacementAlignment: BALANCED
---
flowchart TB
    Alice -->|Since 2021| Bob
    Alice -->|Since 2022| Carol
    Bob -->|Since 2021| Carol
    Bob -->|Since 2020| Dan
    Carol -->|Since 2023| Dan
    Dan -->|Since 2024| Eve

```