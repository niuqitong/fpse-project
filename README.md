# A linux system performance monitoring tool
## [Project Proposal](./Proposal/proposal.md)

## Implementation details
### Calculator
#### CPU usage(percentage) 
**Input:**
```ocaml
type cpu_stats = {
  cpu_id : string;
  user : int;
  nice : int;
  system : int;
  idle : int;
  iowait : int;
  irq : int;
  softirq : int;
}
```
**output**:
```ocaml
type cpu_usage = {
  cpu_id : string;
  usage_pct : float;
}

```
To calculate CPU usage as a percentage, you need to understand how CPU time is divided and tracked in a Linux system. The key information typically comes from the `/proc/stat` file, which provides data on the time the system's CPUs have spent in different states.

**Information Required:Total Time Spent in Various CPU Modes**:
   - **User Mode** (`user`): Time spent executing user processes.
   - **Nice User Mode** (`nice`): Time spent executing user processes with low priority.
   - **System Mode** (`system`): Time spent executing kernel processes.
   - **Idle Mode** (`idle`): Time CPU was idle.
   - **I/O Wait** (`iowait`): Time waiting for I/O to complete.
   - **IRQ** (`irq`): Time servicing interrupts.
   - **SoftIRQ** (`softirq`): Time servicing softirqs.

**Example**:

Assume you read the following `/proc/stat` data at two different times (Time1 and Time2):

- **Time1** - `cpu  4705 150 1120 16250 520 20 5`
- **Time2** - `cpu  4800 160 1200 16500 530 25 10`

**How to Calculate CPU Usage**:

**Step 1: Calculate Total and Idle Times**
- Calculate the total CPU time by summing all time values.
- Calculate the total idle time (which is the `idle` time, often combined with `iowait` time).

**Step 2: Calculate the Difference Over an Interval**
- CPU usage must be calculated over an interval. Record the total and idle times at two different instances (start and end of an interval), then calculate the difference for both.
- ΔTotal = Total_End - Total_Start
- ΔIdle = Idle_End - Idle_Start

**Step 3: Calculate CPU Usage Percentage**
- The CPU usage percentage is then calculated as:
  
  $$ \text{CPU Usage \%} = \left(1 - \frac{\Delta \text{Idle}}{\Delta \text{Total}} \right) \times 100 $$



Calculating ΔTotal and ΔIdle:

- ΔTotal = (4800+160+1200+16500+530+25+10) - (4705+150+1120+16250+520+20+5) 
- ΔIdle = (16500 - 16250)

Then, calculate the CPU Usage % with them
