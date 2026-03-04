connection: "default_bigquery_connection"

include: "/views/*.view.lkml"

datagroup: daily {
  sql_trigger: select current_date() ;;
}

explore: interaction_logs {
  join: status {
    type: left_outer
    sql_on: ${interaction_logs.event_id} = ${status.event_id} ;;
    relationship: one_to_one
  }
  join: status_missing_field {
    type: left_outer
    sql_on: ${status.event_id} = ${status_missing_field.event_id} ;;
    relationship: one_to_one
  }

}
