module P = Collector

type cpu_stats = P.cpu_stats
type memory_info = P.memory_info
type load_average_stats = P.load_average_stats
type process_count = P.process_count
type process_stats = P.process_stats

type cpu_usage_display = {
  cpu_id: string;
  cpu_usage_pct: float;
}

type process_stats_display = {
  pid: int;
  user: string;
  state: string;  (* e.g., "running", "sleeping", etc. *)
  cpu_percentage: float;
  mem_percentage: float;
  command: string;
}

type calculator_output = {
  all_cpu_stats: cpu_usage_display list;
  memory_usage_gb: float * float; (* (Used Memory, all memory) in GB *)
  swap_usage_gb: float * float; (* (Used swap, all Swap) in GB *)
  load_avg: load_average_stats;
  process_cnt: process_count;
  proc_ls: process_stats_display list;
}
module Computer : sig
  val calculate_cpu_usage : cpu_stats list -> cpu_usage_display list
  val calculate_memory_usage : memory_info -> (float * float)
  val calculate_swap_usage : memory_info -> (float * float)
  val calculate_process_list : int -> process_stats list -> process_stats_display list
  val calculate : cpu_stats list -> memory_info -> load_average_stats -> process_count -> process_stats list -> calculator_output
end

module Query : sig
  val compare_pid : process_stats_display -> process_stats_display -> int
  val compare_user : process_stats_display -> process_stats_display -> int
  val compare_state : process_stats_display -> process_stats_display -> int
  val compare_cpu : process_stats_display -> process_stats_display -> int
  
  val compare_mem : process_stats_display -> process_stats_display -> int

  val order_by : ?cpu:bool -> ?mem:bool -> ?user:bool -> ?pid:bool -> ?state:bool -> ?asc:bool -> process_stats_display list -> process_stats_display list

  val filter : ?cpu_range:(float * float) -> ?mem_range:(float * float) -> ?state:string -> ?user:string -> process_stats_display list -> process_stats_display list
end

module Printer : sig
  val clear_terminal : unit -> unit
  val print_bar : float -> int -> string
  val print_calculator_output : calculator_output -> unit
end