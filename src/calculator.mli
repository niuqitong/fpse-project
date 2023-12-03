module P = Collector

type cpu_stats = P.cpu_stats
type memory_info = P.memory_info
type load_average_stats = P.load_average_stats
type process_count = P.process_count
type cpu_usage_display = {
  cpu_id: string;
  cpu_usage_pct: float;
}

type calculator_output = {
    all_cpu_stats: cpu_usage_display list;
    memory_usage_gb: float * float; (* (Used Memory, all memory) in GB *)
    swap_usage_gb: float * float; (* (Used swap, all Swap) in GB *)
    load_avg: load_average_stats;
    process_stats: process_count;
}

val calculate_cpu_usage : cpu_stats list -> cpu_usage_display list
val calculate_memory_usage : memory_info -> (float * float)
val calculate_swap_usage : memory_info -> (float * float)
val calculate : cpu_stats list -> memory_info -> load_average_stats -> process_count -> calculator_output
val print_calculator_output : calculator_output -> unit
