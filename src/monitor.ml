open Core
module P = Collector
module C = Calculator

let () = 
  let final_cpu_status = 
    match P.read_cpu_stats () with
    | hd :: _ -> hd
    | _ -> failwith ""
  in
  let final_memory_info =
    match P.read_memory_info () with
    | Some memory_info -> memory_info
    | None -> failwith "read_memory_info error"
  in
  let final_load_average = 
    match P.read_load_average () with
    | Some load_average -> load_average
    | None -> failwith "read_load_average error"
  in
  let final_process_count = P.read_process_count ()in 
  C.calculate final_cpu_status final_memory_info final_load_average final_process_count
  |> C.print_calculator_output