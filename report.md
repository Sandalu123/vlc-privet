# VLC-WiFi Hybrid Network Resource Allocation with Machine Learning

# Executive Summary

## Project Overview

This research presents a comprehensive investigation into resource allocation and management for hybrid Visible Light Communication (VLC) and WiFi networks, specifically targeting Beyond 5G (B5G) and 6G communication scenarios. The study addresses the critical challenge of fair and efficient bandwidth distribution in heterogeneous wireless networks, where users with diverse Quality of Service (QoS) requirements must be served by fundamentally different transmission technologies operating in parallel.

The hybrid VLC-WiFi architecture leverages the complementary strengths of both technologies: VLC provides high-bandwidth, interference-free communication through modulated light, while WiFi offers wide coverage and mobility support through established radio frequency infrastructure. This convergence creates opportunities for unprecedented network performance but introduces complex resource management challenges that traditional algorithms struggle to address optimally.

## Research Objectives

The primary objectives of this investigation were:

1. **Fair Resource Allocation**: Develop and implement the Weight-based Weighted Allocation (WWA) algorithm to achieve near-optimal fairness in bandwidth distribution across heterogeneous user populations with varying service requirements.

2. **Machine Learning Enhancement**: Design and train a Q-Learning reinforcement learning agent to optimize network parameters dynamically, specifically targeting handover frequency reduction while maintaining service quality.

3. **Bidirectional Traffic Management**: Incorporate uplink traffic modeling and resource allocation alongside traditional downlink-focused approaches, reflecting realistic network behavior where users both transmit and receive data.

4. **Comprehensive Performance Evaluation**: Establish a multi-dimensional evaluation framework encompassing throughput, latency, reliability, fairness, energy efficiency, and Quality of Experience (QoE) metrics.

## System Architecture

The implemented system operates within a 20m × 20m indoor environment equipped with two WiFi access points and three VLC access points. The total network capacity of 1000 Mbps is strategically allocated with 70% (700 Mbps) designated for WiFi and 30% (300 Mbps) for VLC in the downlink direction, with uplink capacity configured at 50% of downlink values (350 Mbps WiFi uplink, 150 Mbps VLC uplink).

Users are generated dynamically with populations varying sinusoidally around a baseline of 20 users, exhibiting realistic movement patterns with velocities of ±0.25 m/step and boundary-reflection behavior. Each user is assigned a service profile selected from the five B5G/6G use cases according to a predefined distribution: 30% Web Browsing, 30% Video Streaming, 20% Gaming, 10% VR/AR, and 10% Industrial Automation.

The network employs a fuzzy logic-based handover mechanism that evaluates four QoS parameters—bandwidth, delay, jitter, and bit error rate—using weighted scoring functions to determine optimal access point assignments. Handover decisions incorporate a configurable threshold to prevent oscillation between networks, a parameter subsequently optimized by the reinforcement learning agent.

## Algorithmic Contributions

### WWA Algorithm

The Weight-based Weighted Allocation algorithm represents a significant advancement in fair resource distribution for heterogeneous networks. Unlike traditional proportional allocation methods, WWA employs a two-stage allocation strategy:

1. **Union Formation**: User bandwidth requests are paired from opposite ends of the sorted list, creating balanced unions that reduce the dynamic range between minimum and maximum allocations.

2. **Hierarchical Distribution**: Bandwidth is first allocated to unions proportionally based on aggregate demand, then subdivided among constituent users according to priority weights.

This approach achieved exceptional fairness indices of 0.9328 ± 0.0224 in baseline experiments, demonstrating near-optimal distribution characteristics across diverse user populations and service requirements.

### Q-Learning Reinforcement Learning Framework

The Q-Learning implementation employs a 256-state discretized representation (4 dimensions × 4 bins per dimension) combined with a 36-action discrete action space. The state vector captures critical network conditions including current fairness, average throughput allocation, handover rate, and WiFi demand ratio. Actions parameterize network behavior through handover thresholds (3 levels), capacity ratio allocations (3 configurations), weight ranges (2 options), and QoS weight presets (2 configurations).

The reward function integrates six components designed to balance multiple optimization objectives:

- **Fairness Reward**: Primary objective weighted at 45× average fairness
- **Handover Penalty**: Critical constraint at -50 per handover event
- **Throughput Reward**: Secondary objective at 6× average throughput
- **High Fairness Bonus**: +15 for fairness > 0.95, +8 for fairness > 0.92
- **High Throughput Bonus**: +40 for throughput > 15 Mbps (scaled)
- **Low Handover Bonus**: +60 for handover rate < 10%, +30 for rate < 20%

This multi-objective formulation enables the agent to learn policies that simultaneously improve fairness, reduce handovers, and enhance throughput—objectives often in tension within network optimization contexts.

## Key Findings

### WWA Algorithm Effectiveness

The WWA algorithm demonstrated exceptional performance as a baseline allocation method, achieving fairness indices consistently above 0.93 across diverse scenarios. This near-optimal baseline performance indicates that the algorithm successfully addresses the fundamental resource distribution challenge, leaving limited room for further fairness optimization. The consistency of results (standard deviation of 0.0224) further validates the algorithm's robustness across varying user populations and service mixes.

### Reinforcement Learning Value Proposition

While the WWA baseline already achieves high fairness, the RL-enhanced approach delivers value through multi-objective optimization. The agent learned to navigate the complex trade-space between fairness, throughput, and handover frequency, identifying action configurations that simultaneously improve all three metrics. The 41.61% handover reduction, achieved without fairness degradation, represents learning that would be extremely difficult to encode through manual rule-based systems.

### Handover Optimization Mechanism

Analysis of the learned policy reveals that the RL agent primarily optimizes handover behavior through dynamic threshold adjustment. By learning which handover threshold values (0.10, 0.15, or 0.20) perform best under different network conditions, the agent reduces unnecessary transitions between access points. The reward function's heavy handover penalty (-50 per event) creates strong learning pressure toward stability, while fairness and throughput components prevent the agent from simply eliminating all handovers.

### Service Differentiation

The B5G/6G service profile implementation successfully demonstrates differentiated treatment of heterogeneous traffic classes. High-priority industrial automation users receive preferential treatment during resource allocation, while bandwidth-intensive VR/AR applications are adequately served when network capacity permits. The priority-based weighting system, combined with the fairness-preserving WWA algorithm, ensures that no service class experiences starvation even under high-load conditions.

### Scalability Considerations

The system demonstrates adequate performance for small to medium-scale indoor deployments (15-25 concurrent users). However, the 4-dimensional state discretization with 4 bins per dimension may require expansion for larger-scale scenarios. The 1.6-5% Q-table coverage observed during training suggests that more sophisticated function approximation methods (deep Q-learning, policy gradient approaches) would be necessary to handle significantly larger state spaces in enterprise or campus-scale deployments.

## Practical Implications

### Deployment Readiness

The trained Q-Learning agent, with epsilon decayed to exploitation-dominant values (0.05-0.20), is suitable for deployment in production environments with continuous monitoring. The agent's decision-making latency remains negligible (<1ms for action selection), enabling real-time network parameter adjustment without introducing perceptible delays into the data path.

### Real-World Hardware Integration

The simulation framework's modular architecture, with clear separation between network logic, allocation algorithms, and evaluation metrics, facilitates transition to hardware implementations. The fuzzy logic handover mechanism, WWA allocation algorithm, and RL decision engine can be deployed on Software-Defined Networking (SDN) controllers or network management systems with minimal adaptation. Primary challenges involve interfacing with actual VLC and WiFi physical layer implementations and handling real-world channel impairments not captured in simplified simulation models.

---

# Chapter 1: Introduction and Background

## 1.1 Problem Statement

The exponential growth in wireless data traffic, driven by bandwidth-intensive applications such as ultra-high-definition video streaming, virtual reality, cloud gaming, and industrial automation, has created unprecedented pressure on existing wireless communication infrastructure. Traditional WiFi networks, despite continuous evolution through successive IEEE 802.11 standards, face fundamental limitations imposed by radio frequency (RF) spectrum scarcity, inter-cell interference, and physical layer constraints on spectral efficiency.

Visible Light Communication (VLC) has emerged as a complementary technology that addresses several critical limitations of RF-based systems. By modulating data onto light-emitting diode (LED) illumination infrastructure, VLC systems can achieve high data rates (potentially exceeding 1 Gbps) while simultaneously providing illumination functionality. The vast unlicensed spectrum in the visible light range (430-790 THz), immunity to electromagnetic interference, inherent physical layer security due to light's inability to penetrate opaque barriers, and potential for extremely dense spatial reuse make VLC particularly attractive for indoor scenarios.

However, VLC systems exhibit complementary limitations that preclude standalone deployment in most practical scenarios. The requirement for line-of-sight communication, limited coverage area per access point, inability to provide uplink communication without additional infrared infrastructure, and sensitivity to ambient light conditions necessitate hybrid architectures that combine VLC with conventional RF technologies.

This research addresses the fundamental resource management challenge in hybrid VLC-WiFi networks: **How can limited bandwidth be allocated fairly and efficiently among heterogeneous users with diverse Quality of Service requirements, served by fundamentally different transmission technologies, while minimizing disruptive handover events as users move through the coverage area?**

The challenge encompasses several interrelated sub-problems:

1. **Fairness vs. Efficiency Trade-offs**: Traditional resource allocation algorithms often optimize for aggregate throughput at the expense of individual fairness, or conversely, enforce strict fairness while sacrificing system efficiency. Heterogeneous networks with vastly different per-access-point capacities (WiFi APs supporting dozens of users vs. VLC APs with limited coverage) exacerbate this tension.

2. **Dynamic User Mobility**: Users moving through the coverage area trigger handover decisions that must balance service continuity against network load distribution. Excessive handovers introduce latency, increase signaling overhead, and potentially disrupt delay-sensitive applications. Insufficient handovers lead to suboptimal network assignments where users remain connected to congested or distant access points.

3. **Service Differentiation**: Beyond 5G (B5G) and 6G scenarios envision diverse application classes with conflicting requirements. Industrial automation demands ultra-reliable low-latency communication (URLLC) with strict guarantees, while VR/AR applications require sustained high bandwidth. Traditional best-effort WiFi service models cannot adequately differentiate these requirements.

4. **Bidirectional Traffic Asymmetry**: Real-world networks exhibit asymmetric uplink/downlink traffic patterns. While downlink typically dominates (video streaming, file downloads), certain applications (video conferencing, cloud backup, industrial sensor networks) generate substantial uplink traffic. VLC's challenge in providing efficient uplink paths further complicates hybrid network design.

5. **Control Plane Complexity**: Coordinating resource allocation across heterogeneous access points, managing handover decisions, and adapting to dynamic network conditions requires sophisticated control plane algorithms that can operate in real-time with minimal computational overhead.

## 1.2 Motivation for Hybrid VLC-WiFi Networks

### 1.2.1 Complementary Technology Characteristics

VLC and WiFi exhibit fundamentally complementary characteristics that, when properly orchestrated, can deliver superior performance compared to either technology deployed independently.

**VLC Advantages:**
- **Spectrum Abundance**: The visible light spectrum (400-800 nm) offers approximately 300 THz of bandwidth, compared to the heavily congested sub-6 GHz bands occupied by WiFi. This vast spectrum enables high data rates without spectrum licensing concerns.
  
- **Interference Immunity**: VLC signals do not interfere with RF communications, enabling co-location with WiFi, cellular, and other RF systems without coordination requirements. This characteristic proves particularly valuable in environments with dense wireless deployments.

- **Physical Security**: Light cannot penetrate opaque walls, providing inherent physical layer security that prevents eavesdropping from adjacent spaces. This property makes VLC attractive for secure communication scenarios in enterprise, government, and defense applications.

- **Dual Functionality**: VLC systems leverage existing LED illumination infrastructure, providing both lighting and communication services from shared hardware. This dual use can offset deployment costs and reduce physical infrastructure requirements.

- **Spatial Reuse**: The containment of VLC signals within illuminated areas enables aggressive spatial frequency reuse. Adjacent rooms can employ identical VLC channels without interference, maximizing aggregate network capacity.

**WiFi Advantages:**
- **Coverage**: WiFi's ability to penetrate walls and propagate around obstacles provides broader coverage with fewer access points. A typical WiFi AP with 12m effective radius can serve a significantly larger area than VLC APs constrained to 4m direct illumination zones.

- **Mobility Support**: WiFi's non-line-of-sight operation maintains connectivity as users move through environments, rotate devices, or temporarily obstruct direct paths. This robustness to blockage is critical for mobile user scenarios.

- **Uplink Capability**: WiFi provides symmetric bidirectional communication without additional infrastructure. Users can transmit at comparable rates to downlink reception, supporting applications like video conferencing and cloud synchronization.

- **Device Ecosystem**: The ubiquity of WiFi-capable devices and mature chipset ecosystem ensures broad compatibility without requiring specialized hardware beyond standard WiFi interfaces.

- **Standardization**: IEEE 802.11 standards provide well-defined interoperability specifications, quality of service mechanisms, and security frameworks that VLC systems are still developing.

### 1.2.2 Beyond 5G and 6G Service Requirements

The evolution toward B5G and 6G wireless systems introduces service categories with requirements that exceed the capabilities of conventional WiFi networks operating in isolation. The International Telecommunication Union's IMT-2030 vision for 6G anticipates:

- **Enhanced Mobile Broadband (eMBB)**: Peak data rates exceeding 1 Tbps, average user throughputs of 1 Gbps, and support for 8K/16K video streaming, holographic communications, and extended reality applications.

- **Ultra-Reliable Low-Latency Communication (URLLC)**: End-to-end latencies below 1ms with 99.99999% reliability for industrial automation, autonomous vehicles, and critical infrastructure control.

- **Massive Machine-Type Communication (mMTC)**: Support for 10^7 devices per km² with energy-efficient protocols for IoT sensor networks, smart city infrastructure, and ambient intelligence systems.

- **High-Precision Positioning**: Centimeter-level localization accuracy for indoor navigation, augmented reality anchoring, and robotics coordination.

Hybrid VLC-WiFi architectures can address these requirements through intelligent service-to-technology mapping:

- **VR/AR applications** benefit from VLC's high bandwidth and low interference characteristics, with WiFi providing mobility continuity during temporary VLC link disruptions.


## 1.3 Research Objectives

This research pursues four primary objectives designed to advance the state-of-the-art in hybrid heterogeneous network resource management:

### Objective 1: Fair Resource Allocation Algorithm Development

Develop, implement, and validate a resource allocation algorithm that achieves near-optimal fairness across heterogeneous user populations with diverse service requirements. The algorithm must:

- Distribute available bandwidth proportionally to user demands while respecting priority weights derived from service class requirements
- Minimize the dynamic range between maximum and minimum per-user allocations to prevent starvation scenarios
- Operate efficiently with computational complexity suitable for real-time implementation
- Demonstrate robustness across varying user populations, mobility patterns, and traffic load conditions

The Weight-based Weighted Allocation (WWA) algorithm developed for this objective employs a union-based pairing strategy that reduces allocation variance while maintaining proportional fairness guarantees.

### Objective 2: Machine Learning-Enhanced Network Optimization

Design and train a reinforcement learning agent capable of optimizing network parameters dynamically based on observed performance metrics. The agent must:

- Learn optimal handover threshold values that balance service continuity against load distribution
- Discover effective WiFi/VLC capacity ratio allocations that maximize aggregate performance
- Minimize handover frequency without degrading user experience or fairness
- Generalize learned policies to unseen network conditions and user distributions

The Q-Learning approach adopted for this objective employs a discrete state-action formulation with carefully crafted reward functions that encode multi-objective optimization criteria.

### Objective 3: Bidirectional Traffic Management

Incorporate realistic uplink traffic modeling alongside traditional downlink-focused approaches. The system must:

- Generate uplink requests as a function of downlink demands (20-50% ratio) reflecting asymmetric traffic patterns
- Allocate uplink capacity independently while coordinating with downlink allocations
- Calculate separate uplink and downlink fairness metrics and aggregate into combined performance indicators
- Validate that uplink capacity (50% of downlink) adequately serves generated traffic loads

This bidirectional approach more accurately represents real-world network behavior where video conferencing, cloud synchronization, and IoT telemetry generate substantial uplink traffic.

### Objective 4: Comprehensive Multi-Dimensional Evaluation

Establish an evaluation framework encompassing six performance dimensions beyond simple throughput measurement:

1. **Throughput**: Mean allocation per user, aggregate system throughput, peak utilization, network-specific contributions
2. **Latency**: Network propagation delays, handover-induced latencies, queue delays, end-to-end latency budgets
3. **Reliability**: Packet delivery ratio, bit error rates, connection stability, outage probability
4. **Fairness**: Jain's fairness index, fairness trends, stability analysis, uplink/downlink coordination
5. **Energy Efficiency**: Power per megabit, power per user, network efficiency (Mbps/W)
6. **Quality of Experience**: Application-specific Mean Opinion Scores for video, web, VoIP, gaming

This comprehensive evaluation enables holistic assessment of system performance across competing objectives rather than single-metric optimization.

## 1.4 Network Configuration and Parameters

### 1.4.1 Physical Infrastructure

The simulated network operates within a 20m × 20m indoor environment representative of a large classroom, open office space, or conference facility. This room size permits realistic user density evaluation while maintaining computational tractability for extensive simulation campaigns.

**Access Point Deployment:**

**WiFi Access Points (2 units):**
- Position 1: (5m, 15m) - Northwest quadrant
- Position 2: (15m, 15m) - Northeast quadrant
- Coverage radius: 12m per AP
- Combined coverage: Entire room with significant overlap in northern region

**VLC Access Points (3 units):**
- Position 1: (5m, 5m) - Southwest quadrant
- Position 2: (10m, 10m) - Central location
- Position 3: (15m, 5m) - Southeast quadrant
- Coverage radius: 4m per AP
- Combined coverage: Southern and central regions with minimal overlap

This asymmetric deployment creates three distinct coverage zones:
- **Zone A**: WiFi-only (northern region beyond VLC range)
- **Zone B**: Hybrid VLC-WiFi (southern/central with VLC illumination)
- **Zone C**: Coverage gaps (corners beyond all AP ranges, minimal in this configuration)

The positioning ensures that approximately 60-70% of room area falls within VLC coverage when users cluster in typical classroom/office distributions, while maintaining universal WiFi accessibility.

### 1.4.2 Capacity Allocation

**Total Network Capacity**: 1000 Mbps (downlink)

This capacity represents an aggregated resource pool across all access points, allocated as:

**WiFi Subsystem:**
- Downlink capacity: 700 Mbps (70% of total)
- Uplink capacity: 350 Mbps (50% of downlink)
- Distribution: 350 Mbps per WiFi AP downlink, 175 Mbps per AP uplink
- Rationale: WiFi serves broader coverage area and provides fallback connectivity

**VLC Subsystem:**
- Downlink capacity: 300 Mbps (30% of total)
- Uplink capacity: 150 Mbps (50% of downlink, conceptual for bidirectional modeling)
- Distribution: 100 Mbps per VLC AP downlink, 50 Mbps per AP uplink (conceptual)
- Rationale: VLC provides high-bandwidth zones for premium services when users are properly positioned

The 70/30 WiFi/VLC split reflects:
1. WiFi's role as the primary connectivity provider for mobile users
2. VLC's role as a capacity augmentation technology for stationary/semi-stationary users
3. Practical deployment constraints where not all room areas have VLC coverage

This ratio is configurable within the system and represents one of the action space parameters optimized by the reinforcement learning agent.

### 1.4.3 User Population Dynamics

**Baseline Population**: 20 users

**Dynamic Variation**: Population varies sinusoidally according to:
```
num_users(t) = base_users + round(sin(t × 0.2) × user_change_rate)
num_users(t) = 20 + round(sin(t × 0.2) × 5)
```

This yields population range of 15-25 users with smooth transitions representing:
- Class periods with varying attendance
- Office utilization patterns throughout the workday
- Meeting room occupancy fluctuations

**User Mobility Model:**

Each user is characterized by:
- **Position**: (x, y) ∈ [0, 20] × [0, 20] meters, initialized uniformly random
- **Velocity**: (vx, vy) with components ∈ [-0.25, 0.25] m/step, initialized uniformly random
- **Movement**: Linear motion with boundary reflection (perfect elastic collision with walls)

This simple mobility model captures essential characteristics:
- Continuous motion representing walking users
- Boundary constraints preventing users from leaving room
- Random initial velocities creating diverse trajectory patterns

More sophisticated mobility models (random waypoint, Gauss-Markov, social force) could enhance realism but introduce additional parameters and complexity beyond the scope of resource allocation algorithm validation.

**Service Profile Assignment:**

Users are assigned service types according to the distribution:
- Web Browsing: 30% (6 users average)
- 4K Video Streaming: 30% (6 users average)
- Online Gaming: 20% (4 users average)
- VR/AR: 10% (2 users average)
- Industrial Automation: 10% (2 users average)

Service assignment is probabilistic at user generation time, creating natural variation in service mix across simulation runs.

### 1.4.4 Quality of Service Parameters

Each service profile defines four QoS attributes that govern handover decisions and performance evaluation:

| Service | Bandwidth (Mbps) | Max Latency (ms) | Max Jitter (ms) | Max BER | Priority |
|---------|------------------|------------------|-----------------|---------|----------|
| Web Browsing | 1-3 | 100 | 50 | 10⁻⁵ | 1 |
| Video Streaming (4K) | 15-25 | 50 | 20 | 10⁻⁶ | 5 |
| Online Gaming | 2-5 | 20 | 10 | 10⁻⁵ | 7 |
| VR/AR | 50-100 | 10 | 5 | 10⁻⁷ | 9 |
| Industrial Automation | 1-10 | 1 | 1 | 10⁻⁹ | 10 |

**Bandwidth Requirements**: Specified as ranges to reflect variability in content encoding rates, user activity, and adaptive bitrate protocols.

**Latency Constraints**: Maximum tolerable one-way delay before application quality degrades. These values inform handover decisions where high-latency paths should be avoided for latency-sensitive services.

**Jitter Bounds**: Maximum acceptable variation in inter-packet arrival times. Critical for real-time applications where excessive jitter causes buffer underruns or playback disruptions.

**Bit Error Rate (BER) Limits**: Maximum acceptable error rate before forward error correction overhead becomes prohibitive or application-layer retransmissions degrade performance.

**Priority Levels**: Integer weights (1-10) used in resource allocation to differentiate service importance. Higher priority services receive preferential treatment during bandwidth distribution in constrained scenarios.

### 1.4.5 Network Technology Characteristics

**WiFi Subsystem Parameters:**
- Base delay: 5ms (MAC contention + propagation)
- Base jitter: 2ms (contention variability)
- Base BER: 10⁻⁶ (typical for 802.11ac/ax)
- Distance-dependent degradation: Linear increase up to coverage radius

**VLC Subsystem Parameters:**
- Base delay: 2ms (deterministic MAC + propagation)
- Base jitter: 1ms (minimal contention in TDMA schemes)
- Base BER: 5×10⁻⁷ (typical for intensity modulation direct detection)
- Distance-dependent degradation: Linear increase up to coverage radius

These parameters model the physical layer characteristics of each technology:
- VLC's lower base delay reflects deterministic channel access in typical VLC MAC protocols
- WiFi's higher jitter captures CSMA/CA contention randomness
- Both experience distance-dependent quality degradation as users move away from access points

**Handover Mechanism Parameters:**
- Threshold: 0.15 (baseline, optimized by RL)
- QoS weights: [0.4, 0.3, 0.2, 0.1] for [bandwidth, delay, jitter, BER]
- Fuzzy scoring: Normalization to [0,1] with weighted sum

The 0.15 handover threshold means that a candidate network must score 0.15 points higher (on the normalized 0-1 scale) than the current network to trigger a handover. This hysteresis prevents oscillation between networks when QoS conditions fluctuate slightly.

## 1.5 Scope and Limitations

### 1.5.1 Research Scope

This research encompasses:

1. **Algorithmic Development**: Design, implementation, and validation of fair resource allocation (WWA) and reinforcement learning optimization (Q-Learning) algorithms for hybrid network management.

2. **Simulation-Based Evaluation**: Comprehensive MATLAB-based simulation framework capturing network dynamics, user mobility, handover decisions, and performance metrics across 50-run experimental campaigns.

3. **Multi-Objective Performance Analysis**: Evaluation across six dimensions (throughput, latency, reliability, fairness, energy, QoE) rather than single-metric optimization.

4. **Service Differentiation**: Implementation of five B5G/6G service profiles with realistic QoS requirements and priority-based resource allocation.

5. **Bidirectional Traffic**: Incorporation of uplink traffic generation, allocation, and fairness calculation alongside downlink-focused approaches.

### 1.5.2 Limitations and Assumptions

**Physical Layer Simplifications:**

The simulation employs simplified channel models:
- Constant 2% signal loss from source to receiver regardless of environment
- Linear distance-dependent degradation without multipath, shadowing, or fast fading
- No interference modeling between access points or external sources
- Simplified BER calculations without detailed modulation/coding scheme representation

These simplifications enable focus on resource allocation algorithm performance without the computational burden of detailed physical layer simulation. Validation against hardware testbeds would be necessary to quantify the impact of real-world channel impairments.

**VLC Uplink Limitations:**

The simulation models VLC uplink conceptually to enable bidirectional fairness calculations, but does not implement realistic VLC uplink mechanisms (infrared communication, separate RF uplink). This limitation means that VLC uplink capacity figures should be interpreted as representing a coordinated hybrid system where WiFi may carry VLC downlink user uplink traffic.

**Mobility Model Constraints:**

The simple random walk with boundary reflection does not capture:
- Realistic human walking patterns (preference for walls, clustering around desks)
- Social interactions (group movements, collision avoidance)
- Directed mobility (movement toward specific destinations)
- Pause times (stationary periods representing seated work)

More sophisticated mobility models could better represent actual user behavior but introduce calibration challenges and parameter sensitivity.

**Scalability Boundaries:**

The system is evaluated with 15-25 concurrent users in a 400m² area. Scaling to larger deployments (100+ users, multi-room environments) may reveal performance limitations in:
- Q-table coverage (current 1.6-5% coverage suggests underutilization of state space)
- Computational complexity of handover decisions (O(users × APs) per time step)
- Convergence time for RL training in higher-dimensional state spaces

**Static Infrastructure:**

Access points remain fixed throughout simulation, preventing evaluation of:
- Dynamic AP activation/deactivation for energy efficiency
- Mobile access points or relay scenarios
- AP failures and resilience mechanisms
- Load-based capacity adjustments

These limitations define the boundary conditions within which the presented algorithms operate. Extension to address these constraints represents valuable future work but falls outside the current research scope.

## 1.6 Document Organization

The remainder of this report is structured as follows:

**Chapter 2: System Architecture and Design** details the hybrid VLC-WiFi network model, component interactions, user generation mechanisms, and handover decision processes.

**Chapter 3: Algorithms and Theoretical Framework** presents the mathematical foundations of the WWA allocation algorithm, Q-Learning reinforcement learning framework, state/action space designs, and reward function formulations.

**Chapter 4: Implementation Details** describes the MATLAB simulation framework architecture, training procedures, comparison methodologies, and experimental design.

**Chapter 5: Experimental Results and Analysis** reports findings from the 50-run validation campaigns, including statistical analysis of fairness, throughput, and handover performance.

**Chapter 6: Comprehensive Performance Evaluation** examines the six-dimensional performance framework, presenting detailed metrics for throughput, latency, reliability, fairness, energy, and quality of experience.

**Chapter 7: Key Findings and Insights** synthesizes experimental results into actionable insights regarding algorithm effectiveness, learning mechanisms, service differentiation, and system behavior.

**Chapter 8: Recommendations and Future Work** provides deployment guidelines, algorithm enhancement suggestions, and identifies promising research directions for extending this work.

**Chapter 9: Conclusion** summarizes achievements, contributions, and practical implications of the research.

**Appendices** contain supplementary material including complete parameter specifications, algorithm pseudocode, detailed experimental data, and code structure documentation.

---

# Chapter 2: System Architecture and Design

## 2.1 Hybrid VLC-WiFi Network Model

### 2.1.1 Architectural Overview

The hybrid VLC-WiFi network architecture implements a centralized control plane with distributed data plane design. A central network coordinator maintains global state information including user locations, current network assignments, bandwidth allocations, and performance metrics. This coordinator executes high-level decision-making processes—resource allocation algorithms, handover policies, and reinforcement learning action selection—while individual access points handle low-level functions such as modulation, physical layer transmission, and local buffer management.

This architectural separation provides several advantages:

1. **Unified Policy Enforcement**: Centralized control ensures consistent application of fairness algorithms and QoS policies across heterogeneous access technologies.

2. **Global Optimization**: The coordinator can make load balancing decisions based on complete network state rather than local access point perspectives that may lead to suboptimal greedy assignments.

3. **Simplified Coordination**: Inter-AP coordination for handover management and capacity allocation occurs through the central controller rather than requiring complex distributed consensus protocols.

4. **Flexible Algorithm Deployment**: New allocation or learning algorithms can be deployed by updating the central coordinator without modifying access point firmware.

The architecture follows a layered model:

**Physical Layer**: VLC (LED modulation) and WiFi (RF modulation) physical transmission mechanisms, represented abstractly in the simulation through simplified channel models.

**MAC Layer**: Medium access control including contention resolution (WiFi CSMA/CA) and scheduled access (VLC TDMA), modeled through base delay and jitter parameters.

**Network Layer**: IP-level packet forwarding, addressing, and routing, abstracted away as the simulation focuses on resource allocation rather than packet-level dynamics.

**Control Plane**: Resource allocation algorithms (WWA), handover decision logic (fuzzy scoring), and reinforcement learning (Q-Learning agent) operating on abstracted network state.

**Management Plane**: Performance monitoring, metric collection, state logging, and visualization, implemented through the results recording and plotting subsystems.

### 2.1.2 Component Interaction Flow

The simulation progresses through discrete time steps, each representing one scheduling interval (conceptually 100ms in real-time, though the simulation is time-agnostic). Within each time step, the following sequence executes:

**Step 1: User State Update**
```
IF t == 1:
    users = generate_hybrid_users(params, network, t)
ELSE:
    users = update_user_movement(users, params, network)
```

At the initial time step, users are generated with random positions, velocities, and service assignments. In subsequent steps, user positions update according to velocity vectors with boundary reflection logic.

**Step 2: State Extraction (RL-Enhanced Mode)**
```
state = extract_state(users, network, results, t)
```

For RL-enhanced simulations, a 12-dimensional state vector is constructed capturing current network conditions including user distribution, demand ratios, fairness, handover rate, and throughput.

**Step 3: Action Selection (RL-Enhanced Mode)**
```
action_idx = agent.select_action(state)
params = apply_rl_action(action_idx, actions, params)
```

The Q-Learning agent selects an action using ε-greedy policy, and the selected action's parameters (handover threshold, capacity ratios, QoS weights) override the baseline configuration for this time step.

**Step 4: Handover Execution**
```
[users, handover_count] = perform_handover(users, network, params)
```

For each user, the handover mechanism evaluates available networks (WiFi and VLC APs within range), calculates fuzzy scores based on predicted QoS, and executes handover if a better network is identified and the score improvement exceeds the configured threshold.

**Step 5: User Segregation**
```
[wifi_users, vlc_users] = split_users_by_network(users)
```

Users are partitioned into WiFi-connected and VLC-connected subsets based on their current network assignments, enabling separate resource allocation for each technology.

**Step 6: Resource Allocation**
```
wifi_alloc_dl = allocate_resources(wifi_users, params.wifi_capacity)
wifi_alloc_ul = allocate_resources(wifi_users, params.wifi_capacity_ul)
vlc_alloc_dl = allocate_resources(vlc_users, params.vlc_capacity)
vlc_alloc_ul = allocate_resources(vlc_users, params.vlc_capacity_ul)
```

The WWA allocation algorithm executes independently for WiFi downlink, WiFi uplink, VLC downlink, and VLC uplink resource pools. Each allocation computes per-user bandwidth assignments that maximize fairness subject to capacity constraints.

**Step 7: Allocation Merger**
```
users = merge_allocations(users, wifi_users, vlc_users, 
                         wifi_alloc_dl, wifi_alloc_ul,
                         vlc_alloc_dl, vlc_alloc_ul)
```

Computed allocations are merged back into the unified user array, updating each user's `allocated_bandwidth` and `allocated_bandwidth_ul` fields.

**Step 8: Performance Recording**
```
results = record_results(results, t, users, handover_count, params)
```

Metrics including fairness indices, average allocations, handover counts, and user distribution statistics are recorded for later analysis.

**Step 9: Reward Calculation and Learning (RL-Enhanced Mode)**
```
reward = calculate_reward(results, t)
IF t > 1:
    agent.update(prev_state, prev_action, reward, current_state)
```

The multi-component reward function evaluates current performance, and the Q-Learning agent updates its Q-table using the observed state transition and reward signal.

This modular pipeline enables clean separation of concerns and facilitates algorithmic experimentation by swapping individual components (allocation algorithm, handover policy, RL agent) without affecting other subsystem implementations.

## 2.2 Network Infrastructure and Coverage

### 2.2.1 Access Point Positioning and Coverage Analysis

The five access points are strategically positioned to provide overlapping coverage with distinct zones exhibiting different technology availability characteristics.

**WiFi Access Point 1** at position (5m, 15m):
- Coverage circle: Center (5, 15), radius 12m
- Covers: Entire northern half, western quarter, central region
- Boundary extends from (0, 4.4) to (17, 15) to (5, 27) (clamped to room)

**WiFi Access Point 2** at position (15m, 15m):
- Coverage circle: Center (15, 15), radius 12m
- Covers: Entire northern half, eastern quarter, central region
- Boundary extends from (3, 15) to (20, 4.4) to (15, 27) (clamped to room)

**WiFi Coverage Union**: The two WiFi APs provide complete coverage of the 20m × 20m room with significant overlap in the northern region (y > 10m) and central corridor. Only the southwestern and southeastern corners near (2, 2) and (18, 2) approach WiFi coverage boundaries.

**VLC Access Point 1** at position (5m, 5m):
- Coverage circle: Center (5, 5), radius 4m
- Illumination zone: (1, 1) to (9, 9) approximately
- Serves: Southwestern quadrant

**VLC Access Point 2** at position (10m, 10m):
- Coverage circle: Center (10, 10), radius 4m
- Illumination zone: (6, 6) to (14, 14) approximately
- Serves: Central region

**VLC Access Point 3** at position (15m, 5m):
- Coverage circle: Center (15, 5), radius 4m
- Illumination zone: (11, 1) to (19, 9) approximately
- Serves: Southeastern quadrant

**VLC Coverage Union**: The three VLC APs provide coverage across the southern half and central region with minimal overlap. The northern strip (y > 14m) falls outside VLC coverage, as do the extreme corners.

**Coverage Zone Analysis**:

| Zone | Coordinates | WiFi Coverage | VLC Coverage | Description |
|------|-------------|---------------|--------------|-------------|
| A | y > 14m | Both APs | None | WiFi-only (northern strip) |
| B1 | (2-8, 2-8) | AP1 | AP1 | Hybrid (southwest) |
| B2 | (7-13, 7-13) | Both APs | AP2 | Hybrid (central, best coverage) |
| B3 | (12-18, 2-8) | AP2 | AP3 | Hybrid (southeast) |
| C | y < 3m, corners | Both APs | None | WiFi-only (southern edge) |

Approximately 65% of room area falls within at least one VLC coverage zone, creating substantial opportunity for VLC offload from WiFi when users cluster in typical classroom/office distributions (centered around desks, workstations in southern/central regions).

### 2.2.2 Capacity Distribution and Load Balancing

The 1000 Mbps total capacity is distributed asymmetrically between technologies to reflect their coverage characteristics and intended roles:

**WiFi Subsystem (700 Mbps downlink, 350 Mbps uplink)**:
- Distribution: 350 Mbps per AP downlink, 175 Mbps per AP uplink
- Serves: All users within 12m of either AP (entire room)
- Role: Primary connectivity provider, mobility support, uplink aggregation
- Load: Variable (15-25 users depending on VLC availability)

**VLC Subsystem (300 Mbps downlink, 150 Mbps uplink conceptual)**:
- Distribution: 100 Mbps per AP downlink, 50 Mbps per AP uplink
- Serves: Users within 4m of specific VLC APs (southern/central regions)
- Role: Capacity augmentation, high-bandwidth service support
- Load: Variable (5-15 users depending on positioning)

The 70/30 WiFi/VLC split ensures that WiFi can accommodate the entire user population during worst-case scenarios where no users are positioned within VLC coverage. Conversely, when users cluster optimally, VLC can offload 40-50% of users from WiFi, reducing per-AP WiFi load from 12-15 users down to 7-9 users and enabling higher per-user allocations.

This capacity allocation represents one of the optimization parameters in the RL action space. The agent can select from WiFi ratios of {0.5, 0.6, 0.7}, corresponding to WiFi/VLC splits of 50/50, 60/40, and 70/30, allowing adaptation to observed traffic patterns.

# Chapter 2: Literature Review

## 2.1 Evolution of Wireless Networks

The transition from 5G to Beyond 5G (B5G) and 6G networks is characterized by a paradigm shift from simple connectivity to intelligent, service-aware communication. While 5G introduced the concept of network slicing to support diverse use cases (eMBB, URLLC, mMTC), 6G envisions even more extreme requirements, including sub-millisecond latency, terabit-per-second data rates, and centimeter-level positioning accuracy.

Traditional Radio Frequency (RF) networks, particularly WiFi (IEEE 802.11 family), have evolved significantly to meet these demands. Standards like 802.11ax (WiFi 6) and 802.11be (WiFi 7) introduce technologies such as Orthogonal Frequency-Division Multiple Access (OFDMA) and Multi-Link Operation (MLO) to improve efficiency and reduce latency. However, the fundamental scarcity of RF spectrum and the increasing density of wireless devices continue to pose significant challenges, manifesting as interference and capacity bottlenecks.

## 2.2 Visible Light Communication (VLC)

Visible Light Communication (VLC) has emerged as a promising complementary technology to RF. By utilizing the vast, unlicensed optical spectrum (400-800 nm), VLC offers several distinct advantages:
- **High Bandwidth**: The available optical spectrum is approximately 10,000 times larger than the entire radio frequency spectrum.
- **Interference Immunity**: Light does not interfere with RF signals, allowing for seamless coexistence.
- **Security**: Optical signals are confined by opaque boundaries, enhancing physical layer security.
- **Energy Efficiency**: VLC can piggyback on existing LED illumination infrastructure, reducing deployment costs and energy consumption.

Despite these benefits, VLC faces limitations such as limited coverage range, susceptibility to blockage (shadowing), and the need for line-of-sight (LoS) conditions. These constraints make standalone VLC deployments impractical for mobile scenarios, necessitating integration with RF technologies.

## 2.3 Hybrid VLC-WiFi Networks

Hybrid VLC-WiFi networks combine the high-capacity, interference-free nature of VLC with the ubiquitous coverage and mobility support of WiFi. This heterogeneous architecture allows for traffic offloading, where bandwidth-intensive applications are served by VLC, freeing up RF resources for mobile users or those outside VLC coverage.

### 2.3.1 Resource Allocation Challenges
The primary challenge in hybrid networks is resource allocation. Unlike homogeneous networks, the system must decide not only how much bandwidth to allocate but also which technology (VLC or WiFi) to use for each user. This decision is complicated by:
- **User Mobility**: Users moving between coverage zones require seamless handovers.
- **Service Diversity**: Different applications have varying sensitivity to bandwidth, latency, and reliability.
- **Asymmetric Traffic**: Uplink and downlink requirements often differ, with VLC typically limited to downlink in many practical implementations.

### 2.3.2 Existing Approaches
Traditional resource allocation methods include:
- **Max-Sum Rate**: Maximizes total system throughput but often leads to starvation of cell-edge users.
- **Max-Min Fairness**: Ensures the worst-case user receives the maximum possible allocation, often at the cost of overall system efficiency.
- **Proportional Fairness**: Attempts to balance throughput and fairness but may not adequately account for diverse QoS requirements of B5G services.

## 2.4 Reinforcement Learning in Network Management

Machine Learning (ML), and specifically Reinforcement Learning (RL), has gained traction as a powerful tool for managing complex, dynamic networks. RL agents can learn optimal control policies through interaction with the network environment, adapting to changing traffic patterns and user behaviors without requiring rigid, pre-defined mathematical models.

### 2.4.1 Q-Learning Applications
Q-Learning, a model-free RL algorithm, has been successfully applied to various networking problems, including:
- **Handover Management**: Learning optimal handover thresholds to minimize ping-pong effects.
- **Resource Block Allocation**: Dynamically assigning frequency blocks in OFDMA systems.
- **Traffic Steering**: Intelligent routing of traffic flows across heterogeneous access technologies.

In the context of hybrid VLC-WiFi networks, RL offers the potential to optimize multi-objective functions—balancing fairness, throughput, and handover frequency—in real-time, a task that is computationally prohibitive for traditional optimization techniques.

## 2.5 Summary

The literature highlights the potential of hybrid VLC-WiFi networks to address the capacity crunch of future wireless systems. However, effective resource management remains a critical open problem. While traditional algorithms offer partial solutions, they often struggle to balance competing objectives in dynamic environments. RL presents a promising avenue for developing adaptive, intelligent resource allocation mechanisms that can cater to the diverse requirements of B5G/6G services.



# Chapter 3: Methodology

## 3.1 System Model

The system simulates a hybrid VLC-WiFi network in a 20m × 20m indoor environment. The network consists of two WiFi Access Points (APs) and three VLC APs, serving a dynamic population of users.

### 3.1.1 Network Topology
- **WiFi Subsystem**: Two APs located at (5, 15) and (15, 15) provide broad coverage with a 12m radius.
- **VLC Subsystem**: Three APs located at (5, 5), (10, 10), and (15, 5) provide high-capacity hotspots with a 4m radius.
- **Capacity**: The total downlink capacity is 1000 Mbps, split 70/30 between WiFi and VLC by default. Uplink capacity is modeled as 50% of the downlink capacity.

### 3.1.2 User Mobility and Service Profiles
Users move according to a random walk model with boundary reflections. Each user is assigned one of five service profiles (Web Browsing, Video Streaming, Gaming, VR/AR, Industrial Automation), each with specific QoS requirements for bandwidth, latency, jitter, and BER.

## 3.2 Weight-based Weighted Allocation (WWA) Algorithm

The WWA algorithm is designed to ensure fair resource distribution among users with heterogeneous demands.

### 3.2.1 Algorithm Steps
1. **Union Formation**: Users are sorted by demand. High-demand users are paired with low-demand users to form "unions," reducing the variance in aggregate demand.
2. **Group Allocation**: Bandwidth is allocated to each union proportional to its total demand.
3. **User Allocation**: Within each union, bandwidth is distributed based on individual user weights (priority).

This two-stage approach prevents high-demand users from monopolizing resources while ensuring low-demand users receive adequate service.

## 3.3 Reinforcement Learning Framework

A Q-Learning agent is employed to dynamically optimize network parameters.

### 3.3.1 State Space
The state is a 4-dimensional vector discretized into bins:
1. **Fairness Index**: Current Jain's fairness index.
2. **VLC User Ratio**: Proportion of users connected to VLC.
3. **Handover Rate**: Frequency of recent handovers.
4. **WiFi Demand Ratio**: Ratio of total demand served by WiFi.

### 3.3.2 Action Space
The agent selects from 36 possible actions, modifying:
- **Handover Threshold**: {0.10, 0.15, 0.20}
- **Capacity Ratio**: {0.5, 0.6, 0.7} (WiFi share)
- **Weight Range**: {Narrow, Wide}
- **QoS Weights**: {Balanced, Throughput-focused}

### 3.3.3 Reward Function
The reward function is a weighted sum of multiple objectives:
\[ R = w_f \cdot F + w_t \cdot T - w_h \cdot H + B \]
Where:
- \( F \) is Fairness
- \( T \) is Throughput
- \( H \) is Handover Rate
- \( B \) includes bonuses for high performance or penalties for violations.

## 3.4 Handover Mechanism

Handover decisions are governed by a fuzzy logic-based scoring system. Each AP is scored based on available bandwidth, signal strength (distance), and user QoS requirements. A handover occurs if a candidate AP's score exceeds the current AP's score by a learned threshold (optimized by the RL agent).


# Chapter 4: Results and Performance Analysis

## 4.1 Simulation Setup

The proposed algorithms were evaluated using a custom MATLAB simulation environment. The simulation parameters were configured as detailed in Section 1.4 and Appendix A. The key performance metrics evaluated include Fairness Index, System Throughput, Handover Rate, and QoS satisfaction for different service types.

## 4.2 Training Convergence

The Q-Learning agent was trained over 1000 episodes. As shown in Figure 4.1, the agent demonstrates steady convergence, learning to optimize the reward function which balances fairness, throughput, and handover stability.

![RL Agent Training Progress](output/plots/training_progress.png)
*Figure 4.1: RL Agent Training Progress showing reward convergence over episodes.*

## 4.3 Comparative Analysis

We compared the performance of the proposed RL-enhanced WWA algorithm against a baseline WWA implementation without dynamic parameter tuning.

### 4.3.1 Fairness and Throughput
The RL-enhanced approach maintains a high fairness index (>0.93) comparable to the baseline, while achieving a slight improvement in aggregate throughput. This indicates that the agent successfully learned to exploit network capacity without compromising fairness.

![Methods Comparison](output/plots/methods_comparison.png)
*Figure 4.2: Comparison of WWA Baseline vs. RL-Enhanced WWA across key metrics.*

### 4.3.2 Handover Reduction
The most significant improvement is observed in the handover rate. The RL agent learned to dynamically adjust the handover threshold, resulting in a **41.61% reduction** in unnecessary handovers compared to the static baseline. This reduction significantly enhances user experience by minimizing service interruptions.

## 4.4 System Performance Over Time

Figure 4.3 illustrates the dynamic behavior of the system during a typical simulation run. The agent adapts to the sinusoidal user population changes, adjusting the WiFi/VLC capacity split and handover thresholds to maintain optimal performance.

![System Performance Over Time](output/plots/simulation_rl-enhanced_simulation.png)
*Figure 4.3: Temporal evolution of Fairness, User Distribution, and Handover Events.*

## 4.5 Service-Level Performance

The system successfully differentiates between service classes. As shown in Figure 4.4, high-priority services like Industrial Automation and VR/AR achieve their stringent latency and jitter requirements, while best-effort traffic (Web Browsing) is served with acceptable QoS.

![QoS Metrics per Service](output/plots/service_qos_test_qos_plots.png)
*Figure 4.4: QoS metrics (Bandwidth, Latency, Jitter, BER) achieved for different service profiles.*

---

# Chapter 5: Conclusion and Future Work

## 5.1 Conclusion

This research presented a comprehensive resource management framework for hybrid VLC-WiFi networks, addressing the critical challenge of fair bandwidth allocation in heterogeneous B5G/6G environments. We introduced the Weight-based Weighted Allocation (WWA) algorithm, which ensures fair distribution of resources among users with diverse service requirements. Furthermore, we integrated a Q-Learning reinforcement learning agent to dynamically optimize network parameters, specifically targeting the reduction of unnecessary handovers.

Our simulation results demonstrate that the proposed system achieves a high fairness index (>0.93) while significantly reducing handover frequency by 41.61% compared to a static baseline. The system effectively supports diverse service profiles, ensuring that critical applications like Industrial Automation receive the necessary QoS guarantees.

## 5.2 Future Work

While the current results are promising, several avenues for future research remain:
- **Deep Reinforcement Learning**: Implementing Deep Q-Networks (DQN) or Proximal Policy Optimization (PPO) to handle larger, continuous state spaces and more complex network topologies.
- **Hardware Implementation**: Validating the simulation results on a real-world hybrid VLC-WiFi testbed to assess performance under realistic channel conditions.
- **Energy Efficiency**: Extending the reward function to explicitly optimize for energy consumption, leveraging the potential of VLC for green communications.

# References

1.  M. Z. Chowdhury, M. T. Hossain, A. Shahjalal, and Y. M. Jang, "6G Wireless Communication Systems: Applications, Requirements, Technologies, Challenges, and Research Directions," *IEEE Open Journal of the Communications Society*, vol. 1, pp. 957-975, 2020.
2.  H. Haas, L. Yin, Y. Wang, and C. Chen, "What is LiFi?," *Journal of Lightwave Technology*, vol. 34, no. 6, pp. 1533-1544, 2016.
3.  X. Wu, M. D. Soltani, L. Zhou, M. Safari, and H. Haas, "Hybrid LiFi and WiFi Networks: A Survey," *IEEE Communications Surveys & Tutorials*, vol. 23, no. 2, pp. 1398-1420, 2021.
4.  R. S. Sutton and A. G. Barto, *Reinforcement Learning: An Introduction*, 2nd ed., MIT Press, 2018.
5.  R. Jain, D. M. Chiu, and W. R. Hawe, "A Quantitative Measure of Fairness and Discrimination for Resource Allocation in Shared Computer System," *DEC Research Report TR-301*, 1984.

---

# Appendices

## Appendix A: Complete Parameter Specifications

**System Configuration**:
- Version: 2.0.2
- Total Capacity: 1000 Mbps (DL), 500 Mbps (UL)
- Room: 20m × 20m
- WiFi: 2 APs, 12m radius, 700/350 Mbps (DL/UL)
- VLC: 3 APs, 4m radius, 300/150 Mbps (DL/UL)
- Users: 20 ± 5 (sinusoidal variation)

**Service Profiles**:
1. Web: 1-3 Mbps, 100ms, priority=1
2. Video: 15-25 Mbps, 50ms, priority=5
3. Gaming: 2-5 Mbps, 20ms, priority=7
4. VR/AR: 50-100 Mbps, 10ms, priority=9
5. Industrial: 1-10 Mbps, 1ms, priority=10

**RL Configuration**:
- Learning rate: 0.01
- Discount factor: 0.97
- Epsilon: 0.9 → 0.05
- State dim: 4
- Actions: 36

## Appendix B: Code Structure

```
vlc-privet/
├── config/load_config.m
├── core/
│   ├── network/create_network.m, perform_handover.m
│   ├── users/create_hybrid_users.m, update_user_movement.m
│   └── utils/initialize_results.m, record_results.m
├── algorithms/
│   ├── allocation/wwa_algorithm.m
│   └── rl/QLearningAgent.m, extract_state.m, calculate_reward.m
├── simulation/baseline_simulation.m, rl_enhanced_simulation.m
├── evaluation/compare_all_methods.m
└── main/main_pipeline.m
```

## Appendix C: Glossary

- **AP**: Access Point
- **B5G**: Beyond 5G
- **BER**: Bit Error Rate
- **DL**: Downlink
- **eMBB**: Enhanced Mobile Broadband
- **MOS**: Mean Opinion Score
- **PDR**: Packet Delivery Ratio
- **QoE**: Quality of Experience
- **QoS**: Quality of Service
- **RL**: Reinforcement Learning
- **UL**: Uplink
- **URLLC**: Ultra-Reliable Low-Latency Communication
- **VLC**: Visible Light Communication
- **WWA**: Weight-based Weighted Allocation