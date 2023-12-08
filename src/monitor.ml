[@@@warning "-33"]
[@@@warning "-32"]

open Core
open Lwt.Infix

module P = Collector
module C = Calculator


let monitor_runner () = 
  let final_cpu_status = P.read_cpu_stats () in
  let final_memory_info =
    match P.read_memory_info () with
    | Some memory_info -> memory_info
    | None -> failwith "read_memory_info error"
  in let final_load_average = 
    match P.read_load_average () with
    | Some load_average -> load_average
    | None -> failwith "read_load_average error"
  in let final_process_list = [] in
  let final_process_count = P.read_process_count () in 
  C.calculate final_cpu_status final_memory_info final_load_average final_process_count final_process_list
  |> C.print_calculator_output;
  print_endline "";
  |> Lwt.return

let rec run_every_sec () = 
  Lwt_unix.sleep 1.0 >>= fun () -> 
  monitor_runner () >>= fun () ->
  run_every_sec ()

let () = 
  let _ = Lwt_main.run (run_every_sec ()) in
  ()
