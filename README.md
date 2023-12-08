# A linux system performance monitoring tool
- [x] Realtime system running metrics monitoring
- [ ] sort, filter processes according to their cpu/memory usage
- [ ] graphic display

# Quick Start
## Build

## Run

## Test


# [Project Proposal](./Proposal/proposal.md)

# Implementation details
## Calculator
### CPU usage(percentage) 
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
type cpu_usage_display = {
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

**Calculations**:

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

### Memory usage

**Input**

```ocaml
type memory_info = {
  mem_total: int;  (* in Kilobytes *)
  mem_free: int;   (* in Kilobytes *)
  swap_total: int; (* in Kilobytes *)
  swap_free: int;  (* in Kilobytes *)
}
```

**Output**

```ocaml
type memory_stats_display = {
  used_memory: float;    (* in GB *)
  total_memory: float;   (* in GB *)
  used_swap: float;      (* in GB *)
  total_swap: float;     (* in GB *)
}
```

**Calculations:**

- **Used Memory**: `Used Memory = (MemTotal - MemFree) / (1024 * 1024)`
- **Used Swap**: `Used Swap = (SwapTotal - SwapFree) / (1024 * 1024)`

### Load average

**Input**
```ocaml
type load_average_stats = {
  one_min_avg : float;
  five_min_avg : float;
  fifteen_min_avg : float;
}
```
**Output**
```ocaml
type load_average_display = {
  one_min_avg : float;
  five_min_avg : float;
  fifteen_min_avg : float;
}
```
**Load average can be directly read. No need for further calculation. Input and output are the same. Here is just for the purpose of explicit layering**.  
The load average is typically calculated as a moving average of the sum of the number of runnable processes and the number of processes in uninterruptible sleep.  
In Linux, the load average can usually be read directly from the `/proc/loadavg` file, which provides the 1-minute, 5-minute, and 15-minute load averages. For example, the file might contain:

```bash
0.00 0.01 0.05 1/189 1234
```
Here, 0.00, 0.01, and 0.05 are the 1-minute, 5-minute, and 15-minute load averages, respectively.

### Process count

**Input**

```ocaml
type process_count = {
  total_processes: int;
  total_threads: int;
  n_running_tasks: int;  (* Detailed info for a subset of processes *)
}
```



**Output**

```ocaml
type process_count_display = {
  total_processes: int;
  total_threads: int;
  n_running_tasks: int;  (* Detailed info for a subset of processes *)
}
```



### Process list

**Input**

```ocaml
type process_stats = {
  pid: int;
  utime: int;
  stime: int;
  total_cpu_time: int;
  vm_rss: int; (* resident set size *)
  uid: int; (* used for get user *)
  cmdline: string;
  (* Additional fields as needed based on /proc/[pid]/stat and /proc/[pid]/status *)
}
type process_stats_list = process_stats list
```



**Output**  

```ocaml
type process_stats_display = {
  pid: int;
  user: string;
  state: string;  (* e.g., "running", "sleeping", etc. *)
  cpu_percentage: float;
  mem_percentage: float;
  command: string;
  (* Additional fields as needed based on /proc/[pid]/stat and /proc/[pid]/status *)
}
type process_stats_list_display = process_stats_display list
```

**CPU usage calculation**

- From `/proc/[pid]/stat`, get the process's `utime` and `stime`.
- Calculate the total time spent for the process: `total_time = utime + stime`.
- Get total CPU time from `/proc/stat`.
- CPU usage % = `(total_time / total_cpu_time) * 100`.

**Memory usage calculation**

- From `/proc/[pid]/status`, get `VmRSS` (Resident Set Size).
- Get total system memory from `/proc/meminfo`.
- Memory usage % = `(VmRSS / total_memory) * 100`.

**Get username from `uid`**

Use system calls provided by the OS to look up user information based on the UID. In OCaml, use the Unix module which provides access to system calls.

- Use the `Unix.getpwuid` function, which returns a record containing the username and other details of the user with the given UID.

Here’s an example in OCaml:

```ocaml
let get_username_from_uid uid =
  try
    let user_entry = Unix.getpwuid uid in
    user_entry.Unix.pw_name
  with
  | Not_found -> "Unknown"
```

Or read `/etc/passwd`

