
open Core
open Lwt.Infix
open Calculator

module CpuCollector = Collector.RealCPUCollector
module AvgCollector = Collector.RealLoadAvgCollector
module ProcCountCollector = Collector.RealProcCountCollector
module MemCollector = Collector.RealMemCollector
module ProcessesCollector = Collector.RealProcessesCollector

module Computer = Calculator.Computer
module Printer = Calculator.Printer
module Query = Calculator.Query

type feature = No_feature | Order of string * bool | Filter_category of string * string | Filter_number of string * float * float
type argument_error = Invalid_args | Invalid_item | Invalid_ASC | Invalid_operator | Invalid_number


let catergory_item = ["user"; "state"]
let number_item = ["cpu"; "mem"; "pid"]

let monitor_runner feature = 
  let final_cpu_status = CpuCollector.read_cpu_stats () in
  let final_memory_info =
    match MemCollector.read_memory_info () with
    | Some memory_info -> memory_info
    | None -> failwith "read_memory_info error"
  in let final_load_average = 
    match AvgCollector.read_load_average () with
    | Some load_average -> load_average
    | None -> failwith "read_load_average error"
  in let raw_process_list = ProcessesCollector.collect_process_stats ()
  in let final_process_count = ProcCountCollector.read_process_count () 
  in let final_output = Computer.calculate final_cpu_status final_memory_info final_load_average final_process_count raw_process_list
  in let no_feature_process_display_list = final_output.proc_ls
  in let final_process_display_list = match feature with
    | No_feature -> no_feature_process_display_list   
    | Order ("cpu", asc) -> Query.order_by ~cpu:true ~asc:asc no_feature_process_display_list
    | Order ("user", asc) -> Query.order_by ~user:true ~asc:asc no_feature_process_display_list
    | Order ("mem", asc) -> Query.order_by ~mem:true ~asc:asc no_feature_process_display_list
    | Order ("pid", asc) -> Query.order_by ~pid:true ~asc:asc no_feature_process_display_list
    | Order ("state", asc) -> Query.order_by ~state:true ~asc:asc no_feature_process_display_list
    | Filter_category ("state", value) -> Query.filter ~state:value no_feature_process_display_list
    | Filter_category ("user", value) -> Query.filter ~user:value no_feature_process_display_list
    | Filter_number ("mem", lower_bound, upper_bound) -> Query.filter ~mem_range:(lower_bound, upper_bound) no_feature_process_display_list
    | Filter_number ("cpu", lower_bound, upper_bound) -> Query.filter ~cpu_range:(lower_bound, upper_bound) no_feature_process_display_list
    | _ -> failwith "Error in Argument"
  in Printer.print_calculator_output {final_output with proc_ls = final_process_display_list}
  |> Lwt.return
 

let rec run_every_sec feature = 
  monitor_runner feature >>= fun () ->
  Lwt_unix.sleep 1.0 >>= fun () -> 
  run_every_sec feature


let parse_args args =
      match args with
      | [""] -> Ok (No_feature)
      | "ORDER_BY" :: item :: rest ->
        if List.exists catergory_item ~f:(fun element -> String.compare element item = 0) || 
        List.exists number_item ~f:(fun element -> String.compare element item = 0) then
          if List.length rest = 0 then Ok (Order (item, false))
          else match rest with 
          | "ASC" :: [] -> Ok (Order (item, true)) 
          | _ -> Error (Invalid_ASC)         
      else Error (Invalid_item) 
      | "ORDER_BY" :: _ -> Error (Invalid_args)
      | "SELECT" :: item :: operator :: value :: [] ->
        if List.exists catergory_item ~f:(fun element -> String.compare element item = 0) then 
          if String.compare operator "=" = 0 then Ok (Filter_category (item, value))
          else Error (Invalid_operator)
        else if List.exists number_item ~f:(fun element -> String.compare element item = 0) then
          try 
            if String.compare operator "<" = 0 then Ok (Filter_number (item, 0.0, float_of_string value))
            else if String.compare operator ">" = 0 then Ok (Filter_number (item, float_of_string value, 100.0))
            else if String.compare operator "=" = 0 then Ok (Filter_number (item, float_of_string value, float_of_string value))
            else Error (Invalid_operator)
           with | Failure _ -> Error (Invalid_number) 
        else Error (Invalid_item)
      | _ -> Error (Invalid_args)
    

let rec present_homepage () = 
  Sys_unix.command "clear" |> ignore;
  print_string 
  "Welcome to our Linux System Monitor.

  ---- Basic Usage ----
For all system information: press enter.

  ---- Order Feature ----
To order the processes list: ORDER_BY [item] ASC. 
- Replace [item] with cpu/mem/state/user/pid/state. 
- Omit ASC if you want results in descending order. 
Press enter.

  ---- Filter Feature ----
To filter the processes list: SELECT [item] [comparison operator] [value]
- Replace [item] with cpu/mem/state/user/pid.
- Replace [comparison operator] with </>/=, depending on your desired filter condition.
- Replace [value] with a float or a string, depending on your desired filter condition.
Press enter.\n";  
  match (parse_args (String.split_on_chars (Out_channel.(flush stdout); In_channel.(input_line_exn stdin)) ~on:[' '])) with
  | Ok (feature) -> Lwt_main.run (run_every_sec feature)
  | Error (Invalid_args) -> print_string "You provided invalid arguments. Please try again.\n------------------------\n"; present_homepage ()
  | Error (Invalid_item) -> print_string "The item you asked about is invalid. Please check the instrctions.\n------------------------\n"; present_homepage ()
  | Error (Invalid_number) -> print_string "You provided an invalid number. Please try again.\n------------------------\n"; present_homepage ()
  | Error (Invalid_operator) -> print_string "You provided an invalid comparison operator. Please try again.\n------------------------\n"; present_homepage ()
  | Error (Invalid_ASC) -> print_string "You can ask for results in ascending order by typing ASC; otherwise omit it. Try again.\n------------------------\n"; present_homepage ()

let () = 
  present_homepage ()
