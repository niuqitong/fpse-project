[@@@warning "-34"]
open Batteries
module type CPUReader = sig
  val lines_of : string -> string list
end
module type MemReader = sig
  val lines_of : string -> string Enum.t
end
module type LoadAvgReader = sig
  val read_lvg : string -> string option
end
module type ProcCountFileReader = sig
  val read_directory : string -> string array option
  val read_line : string -> string option
end
module type ProcessesFileReader = sig
  val read_line : string -> string option
  val read_directory : string -> string array option
  val getpwuid : int -> (string, string) result
end

module Cpu_collector (_ : CPUReader) : sig
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

  val parse_cpu_stats_line : string -> cpu_stats option
  val read_cpu_stats : unit -> cpu_stats list
  val string_of_cpu_stats : cpu_stats -> string
end

module Process_count_collector(_ : ProcCountFileReader) : sig
  type process_count = {
    total_processes: int;
    total_threads: int;
    n_running_tasks: int;
  };;
  val read_process_count : process_count 

end

module Mem_collector(_ : MemReader) : sig 
  type memory_info = {
    mem_total: int;  
    mem_free: int;   
    swap_total: int; 
    swap_free: int;  
  };;
  val read_memory_info : unit -> memory_info option 
end

module ProcessesCollector(_ : ProcessesFileReader) : sig
  type process_stats = {
  pid: int;
  utime: int;
  stime: int;
  total_cpu_time: int;
  total_time: int;
  vm_rss: int;
  state: string;
  username: string;
  uid: int;
  cmdline: string;
};;

val read_process_stats : int -> process_stats 
val collect_process_stats : process_stats list 
end

module LoadAvg_collector(_ : LoadAvgReader) : sig

  type load_average_stats = {
    one_min_avg : float;
    five_min_avg : float;
    fifteen_min_avg : float;
  };;

  val read_load_average : unit -> load_average_stats option 
end

(* type cpu_stats = {
  cpu_id : string;
  user : int;
  nice : int;
  system : int;
  idle : int;
  iowait : int;
  irq : int;
  softirq : int;
};; *)

(* type memory_info = {
  mem_total: int;  (* in Kilobytes *)
  mem_free: int;   (* in Kilobytes *)
  swap_total: int; (* in Kilobytes *)
  swap_free: int;  (* in Kilobytes *)
};;

type load_average_stats = {
  one_min_avg : float;
  five_min_avg : float;
  fifteen_min_avg : float;
};;

type process_count = {
  total_processes: int;
  total_threads: int;
  n_running_tasks: int;
};;


type process_stats = {
  pid: int;
  utime: int;
  stime: int;
  total_cpu_time: int;
  total_time: int;
  vm_rss: int;
  state: string;
  username: string;
  uid: int;
  cmdline: string;
};; *)

(* val read_cpu_stats : unit -> cpu_stats list *)
(* val read_memory_info : unit -> memory_info option
val read_load_average : unit -> load_average_stats option
val read_process_count : unit -> process_count
val read_process_stats : int -> process_stats
val list_pids : unit -> int list
val collect_process_stats : unit -> process_stats list *)