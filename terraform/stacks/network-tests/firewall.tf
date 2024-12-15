# variable "rules" {
#   type = list(object({
#     action             = string
#     jump_target        = optional(string)
#     connection_state   = optional(string)
#     in_interface       = optional(string)
#     in_interface_list  = optional(string)
#     out_interface_list = optional(string)
#     src_address        = optional(string)
#     dst_address        = optional(string)
#     src_port           = optional(string)
#     dst_port           = optional(string)
#     protocol           = optional(string)
#     comment            = optional(string, "(terraform-defined)")
#     log                = optional(bool, false)
#     disabled           = optional(bool, false)
#   }))
#
#   default = []
# }

variable "tf_comment_prefix" {
  type    = string
  default = "(terraform-defined)"
}

locals {
  input_rules_pre = [
    { chain = "input", action = "accept", connection_state = "established,related" },
    # TODO: make this more granular, allow vlans access to router services
    { chain = "input", action = "accept", in_interface_list = "LOCAL" },
    { chain = "input", action = "accept", in_interface = var.mgmt_port },
    # NOTE: Allow MGMT vlan full access to the device
    { chain = "input", action = "accept", in_interface_list = "MGMT" },
  ]

  input_rules_post = [
    # TODO: replace with drop
    { chain = "input", action = "log" },
  ]

  input_rules = concat(
    local.input_rules_pre,
    local.input_rules_post,
  )

  forward_rules_pre = [
    { chain = "forward", action = "accept", connection_state = "established,related" },
    # Allow all VLANS to access to internet only
    { chain = "forward", action = "accept", in_interface_list = "LOCAL", out_interface_list = "WAN" },
    # Allow mgmt VLAN access to all vlans
    { chain = "forward", action = "accept", in_interface_list = "MGMT" }
  ]

  forward_rules_post = [
    # TODO: replace with drop
    { chain = "forward", action = "log" },
  ]

  forward_rules = concat(
    local.forward_rules_pre,
    local.forward_rules_post,
  )

  filter_rules = concat(local.input_rules, local.forward_rules)

  srcnat_rules_pre = [
    { chain = "srcnat", action = "masquerade", out_interface_list = "WAN" },
  ]

  srcnat_rules_post = [
    # { chain = "srcnat", action = "drop" },
  ]

  srcnat_rules = concat(
    local.srcnat_rules_pre,
    local.srcnat_rules_post,
  )

  nat_rules = local.srcnat_rules

  # https://discuss.hashicorp.com/t/does-map-sort-keys/12056/2
  # Map keys are always iterated in lexicographical order!
  filter_rule_map = { for idx, rule in local.filter_rules : format("%03d", idx) => rule }
  nat_rule_map    = { for idx, rule in local.nat_rules : format("%03d", idx) => rule }
}

resource "routeros_ip_firewall_filter" "rules" {
  for_each          = local.filter_rule_map
  chain             = lookup(each.value, "chain", null)
  action            = lookup(each.value, "action", null)
  jump_target       = lookup(each.value, "jump_target", null)
  comment           = lookup(each.value, "comment", var.tf_comment_prefix)
  log               = lookup(each.value, "log", null)
  disabled          = lookup(each.value, "disabled", null)
  connection_state  = lookup(each.value, "connection_state", null)
  in_interface      = lookup(each.value, "in_interface", null)
  in_interface_list = lookup(each.value, "in_interface_list", null)
  src_address       = lookup(each.value, "src_address", null)
  dst_port          = lookup(each.value, "dst_port", null)
  protocol          = lookup(each.value, "protocol", null)
}

resource "routeros_move_items" "filter_rules" {
  resource_path = "/ip/firewall/filter"
  sequence      = [for i, _ in local.filter_rule_map : routeros_ip_firewall_filter.rules[i].id]
  depends_on    = [routeros_ip_firewall_filter.rules, module.vlans]
}

resource "routeros_ip_firewall_nat" "rules" {
  for_each          = local.nat_rule_map
  chain             = lookup(each.value, "chain", null)
  action            = lookup(each.value, "action", null)
  jump_target       = lookup(each.value, "jump_target", null)
  comment           = lookup(each.value, "comment", var.tf_comment_prefix)
  log               = lookup(each.value, "log", null)
  disabled          = lookup(each.value, "disabled", null)
  in_interface      = lookup(each.value, "in_interface", null)
  in_interface_list = lookup(each.value, "in_interface_list", null)
  src_address       = lookup(each.value, "src_address", null)
  dst_port          = lookup(each.value, "dst_port", null)
  protocol          = lookup(each.value, "protocol", null)
}

resource "routeros_move_items" "nat_rules" {
  resource_path = "/ip/firewall/nat"
  sequence      = [for i, _ in local.nat_rule_map : routeros_ip_firewall_nat.rules[i].id]
  depends_on    = [routeros_ip_firewall_nat.rules, module.vlans]
}
