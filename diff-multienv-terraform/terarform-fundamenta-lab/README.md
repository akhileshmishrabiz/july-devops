# Terraform fundamentals lab

**Bootcamp:** July DevOps  
**Topic:** `count`, `for_each`, locals, map transforms, conditionals, dynamic blocks, and a network module  
**Folder:** `diff-multienv-terraform/terarform-fundamenta-lab`

This lab is the hands-on for the module class. You will run small examples first, then read a network module that uses the same ideas to create as many subnets as the caller lists.

Remote state and multi-environment layout are a later class. Everything here is one root module, or a root module calling a local module.

Parts 1–6 use `local_file` so you can apply them on your laptop. The arguments are the same ones you put on `aws_instance`: `count`, `for_each`, `count.index`, `each.key`, `each.value`.

---

## Prerequisites

- Terraform `>= 1.5`
- Parts 1–6 and `terraform test` in part 8 need no AWS account
- `terraform plan` / `apply` in parts 7 and 8 need AWS credentials and a region you can use (`ap-south-1` in the lab file)

From this folder:

```bash
cd diff-multienv-terraform/terarform-fundamenta-lab
```

Each numbered folder is a finished example. Read the part, run the commands, then make the change and run again. Say what you expect the plan to do before you look.

When you are done with a folder you applied:

```bash
terraform destroy -auto-approve
```

---

## Map of the lab

| Part | Folder | Idea |
|------|--------|------|
| 1 | `01-count` | Repeat one configuration. Addresses are `[0]`, `[1]`, `[2]`. |
| 2 | `02-foreach-set` | `for_each` on a set. Duplicates are dropped. |
| 3 | `03-map-and-each` | `for_each` on a map. Each copy has its own settings. |
| 4 | `04-map-transform` | A `for` expression builds that map from a list. |
| 5 | `05-conditionals` | `count = condition ? 1 : 0`, and the NAT count decision. |
| 6 | `06-filter-map` | A second map so only some services get a load balancer. |
| 7 | `07-dynamic-block` | Repeat a nested block (`ingress`). |
| 8 | `08-network-module` | A reusable VPC module driven by lists and those decisions. |

---

## Part 1 — `count`

`count` creates the resource that many times. Every copy shares the same AMI and instance type. Terraform numbers the copies from zero.

```bash
cd 01-count
terraform init
terraform apply -auto-approve
terraform state list
cat out/web-1.txt
```

You should see:

- State addresses `local_file.web[0]`, `local_file.web[1]`, `local_file.web[2]`
- Files `web-1.txt`, `web-2.txt`, `web-3.txt`
- `web-1.txt` contains `count_index=0`

`count.index` is `0`, then `1`, then `2`. The filename adds 1 so a person reads `web-1`. The state address stays `[0]`.

`local_file.web[0]` is how you point at the first one. `local_file.web[*].filename` is the whole list. The output `first_instance_file` is that first address.

### Change it

1. Set `count = 1`, apply, and confirm only `web-1.txt` remains.
2. Set `count = 0`, apply, and confirm the file is gone. Zero means the resource is absent.
3. Put `count` back to `3`.

On a real instance the same block looks like this:

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = local.ami
  instance_type = local.instance_type

  tags = {
    Name = "web-${count.index + 1}"
  }
}
```

`count` is the right tool when every copy is the same. Part 3 is what you use when they are not.

---

## Part 2 — `for_each` on a set

```bash
cd ../02-foreach-set
terraform init
terraform apply -auto-approve
terraform state list
terraform output
```

The list has four entries because `web-1` is written twice. The set has three. You get three files and three state addresses:

```text
local_file.web["web-1"]
local_file.web["web-2"]
local_file.web["web-3"]
```

Outputs: `list_length = 4`, `set_length = 3`.

A resource address has to be unique. A set drops duplicates, so Terraform can use each value as an address. On a set of strings, `each.key` and `each.value` are the same string. Open `out/web-2.txt` and check that.

### See the list error

In `main.tf`, comment out `for_each = toset(local.names)` and uncomment `for_each = local.names`. Then:

```bash
terraform validate
```

Terraform reports that `for_each` must be a map or a set of strings, and that `local.names` is a tuple. Put `toset(...)` back before you go on.

`toset()` is the conversion, the same way `tostring()` and `tonumber()` convert other types.

---

## Part 3 — a map, `each.key`, and `each.value`

`count` cannot give `web-1` a `t2.micro` and `web-2` a `t3.medium`. A map can. The key is the name you will use in state. The value holds the settings for that name.

```bash
cd ../03-map-and-each
terraform init
terraform apply -auto-approve
terraform state list
cat out/web-2.txt
```

`out/web-2.txt` should contain `ami=ami-ubuntu` and `instance_type=t3.medium`. The state address is `local_file.web["web-2"]`.

Inside the resource:

- `each.key` is `web-1`, `web-2`, or `web-3`
- `each.value.ami` and `each.value.instance_type` are the fields of that object

Swap the `web-1` and `web-2` blocks in the map and apply again. The plan should show no change. The address is the key, so order in the file does not rename the resource.

`toset()` does not turn a list of objects into something `for_each` can use. `for_each` on a set accepts strings. A set of objects produces: `"for_each" supports maps and sets of strings, but you have provided a set containing type object.`

---

## Part 4 — build the map from a list

People who call your module should edit a list. They should not have to hand-write the map. A `for` expression does that conversion. This is the same idea as a Python dictionary comprehension.

```hcl
instance_map = {
  for instance in local.instance_list : instance.name => instance
}
```

Read it as: for each object in the list, use `instance.name` as the key and the whole object as the value.

```bash
cd ../04-map-transform
terraform init
terraform apply -auto-approve
terraform output instance_map
```

The output map should match the hand-written map from part 3: keys `web-1`, `web-2`, `web-3`, and each value still has `ami` and `instance_type`.

Two more outputs read the list by position, which is what you do when you still want “the first” and “the second”:

- `local.instance_list[0].name` → `web-1`
- `local.instance_list[1].name` → `web-2`

Indexes start at 0.

You can also inspect the local before you trust the resource:

```bash
terraform console
```

```text
> local.instance_map
```

Type `exit` to leave the console.

### Change it

Add a fourth object, `web-4`, with any AMI and instance type. Apply. You should get one new file, `out/web-4.txt`, and the previous three addresses should stay as they are. Remove `web-4` again before part 5.

That is the platform pattern: a developer adds one object to the list, and the loop creates the resource. The module author writes the loop once.

---

## Part 5 — conditionals

```hcl
count = var.want_instance ? 1 : 0
```

The condition is first. The value after `?` is used when the condition is true. The value after `:` is used when it is false. `1` creates one resource. `0` creates none.

```bash
cd ../05-conditionals
terraform init
terraform apply -auto-approve
terraform output
```

Default result: `nat_count = 1` and `instance_file_count = 1`. `out/web.txt` exists.

The NAT decision is the same shape, nested one level:

```hcl
nat_count = (
  var.need_nat_gateway
  ? (var.need_single_nat_gateway ? 1 : var.public_subnet_count)
  : 0
)
```

| `need_nat_gateway` | `need_single_nat_gateway` | `public_subnet_count` | `nat_count` |
|--------------------|---------------------------|-----------------------|-------------|
| true | true | 2 | 1 |
| false | true | 2 | 0 |
| true | false | 3 | 3 |

Run those three and check the output:

```bash
terraform apply -auto-approve -var need_nat_gateway=false
terraform apply -auto-approve -var need_nat_gateway=true -var need_single_nat_gateway=false -var public_subnet_count=3
terraform apply -auto-approve -var want_instance=false
```

The last command removes `out/web.txt` and sets `instance_file_count` to `0`. `nat_count` goes back to `1` because you stopped overriding the NAT variables.

`length(var.public_subnet_data)` is how the module will know the subnet count. Here that number is the variable `public_subnet_count`.

---

## Part 6 — a second map for a subset

A frontend should sit behind a load balancer. A backend should not. Both are still services, so both are created from `services_map`. A second map, `alb_services`, keeps only the objects where `need_alb` is true.

```bash
cd ../06-filter-map
terraform init
terraform apply -auto-approve
terraform output
ls out
```

You should see:

- `service_keys` = `backend` and `frontend`
- `alb_keys` = `frontend` only
- Files `backend.txt`, `frontend.txt`, and `frontend-alb.txt`

There is no `backend-alb.txt`.

The filter:

```hcl
alb_services = {
  for name, service in local.services_map : name => service
  if service.need_alb
}
```

### Change it

Set `need_alb = true` on the backend object and apply. A `backend-alb.txt` file should appear. Set it back to `false` and apply again. The backend service file stays; the ALB file goes away.

The caller’s job is the list: name, image, port, and whether they want a load balancer. The loop decides which extra resources exist.

---

## Part 7 — dynamic blocks

`count` and `for_each` repeat a whole resource. A **dynamic block** repeats a nested block inside one resource. Security group ingress is the usual case: two rules should be two `ingress` blocks, written from a list so a third rule is another object, not another copy of the block.

```bash
cd ../07-dynamic-block
terraform init
terraform validate
```

`Success! The configuration is valid.` is the checkpoint. `validate` checks the configuration. It does not talk to AWS.

The block:

```hcl
dynamic "ingress" {
  for_each = var.ingress_rules
  iterator = rule

  content {
    description = rule.value.description
    from_port   = rule.value.from_port
    to_port     = rule.value.to_port
    protocol    = rule.value.protocol
    cidr_blocks = [rule.value.cidr]
  }
}
```

`for_each` here walks the list of rule objects. `content` is the real `ingress` block. `iterator = rule` names the current item `rule`. The default name would be `ingress` (the block type). An explicit name matters when the resource itself also has `each.key` / `each.value`: those still mean the resource, and `rule.value` means the nested item.

### Load balancer block on the frontend only

Part 6 created a separate resource for the load balancer attachment. Sometimes the attachment is a nested block on a resource you already create for every service. A dynamic block with an empty list creates the block zero times:

```hcl
dynamic "load_balancer" {
  for_each = each.value.need_alb ? [1] : []

  content {
    container_name = each.key
    container_port = each.value.port
  }
}
```

`each` is the service (`frontend`, `backend`). When `need_alb` is true, `for_each` is a one-item list, so one `load_balancer` block is written. When it is false, `for_each` is `[]`, so the block is omitted. `[1]` is only there to make a list of length 1. The value `1` is not a port.

This snippet is the shape of an ECS service. It is here to read. It is not a second resource in `07-dynamic-block`.

### Optional apply

If you have a VPC id:

```bash
terraform plan -var vpc_id=vpc-xxxxxxxx
```

The plan should show one security group with the HTTP and HTTPS ingress rules from `ingress_rules`. Add a third object (for example SSH on port 22) and plan again. You should see one more ingress rule. Destroy the group if you apply it.

---

## Part 8 — network module

A module is a folder other stacks can call. The caller passes variables. The module creates the resources and returns outputs. Hardcoded names stay out of the module so the next caller can use it with different input.

```text
08-network-module/
  versions.tf          # Terraform and provider versions for the root
  providers.tf         # AWS provider, region from a variable
  variables.tf         # what this stack asks for
  main.tf              # builds the VPC name and calls the module
  outputs.tf           # re-exports module outputs, plus list indexes
  lab.tfvars           # the lab inputs: two public subnets, two private, NAT off
  tests/nat.tftest.hcl # plans the module without AWS
  modules/network/
    versions.tf
    variables.tf       # vpc name, DNS flags, subnet lists, NAT flags
    network.tf         # VPC, subnets, routes, NAT
    outputs.tf         # vpc id, subnet ids, NAT count
```

The root module configures the provider. The child module only says which provider it needs.

### What to read, in order

1. `modules/network/variables.tf`  
   `vpc_name` is a variable. `enable_dns_hostnames` defaults to `false`, so DNS hostnames stay off until a caller sets them. `public_subnet_data` and `private_subnet_data` are lists of objects (`name`, `cidr`, `availability_zone`, `prefix`). Names must be unique because they become `for_each` keys.

2. `modules/network/network.tf` locals  
   The list becomes a map the same way as part 4:

   ```hcl
   public_subnets = {
     for subnet in var.public_subnet_data : subnet.name => subnet
   }
   ```

   `nat_count` is the part 5 expression. `length(var.public_subnet_data)` replaces the hardcoded subnet count.

3. Subnets  
   `aws_subnet.public` and `aws_subnet.private` use `for_each`. Two objects in the list create two subnets. A third object creates a third. The name tag is `${var.vpc_name}-${each.value.prefix}-${each.key}`, so the lab’s first public subnet is tagged `devops-lab-vpc-public-a`.

4. NAT  
   `aws_eip.nat` and `aws_nat_gateway.nat` use `count = local.nat_count`. The gateway is placed in `public_subnet_names[count.index]`, so the first NAT goes in the first public subnet in the list.

   | Flags | What you get |
   |-------|----------------|
   | `need_nat_gateway = false` | No NAT. Private subnets share a route table with no default route. |
   | `need_nat_gateway = true`, `need_single_nat_gateway = true` | One NAT in the first public subnet. Every private subnet uses that NAT. |
   | `need_nat_gateway = true`, `need_single_nat_gateway = false` | One NAT per public subnet. Each private subnet uses the NAT in its own availability zone. |

5. `modules/network/outputs.tf`  
   A module returns only what this file exports. `public_subnet_ids` and `private_subnet_ids` are maps of name → id.

6. Root `main.tf` and `outputs.tf`  
   The VPC name is composed in the caller:

   ```hcl
   vpc_name = "${var.app_name}-${var.environment}-vpc"
   ```

   With the lab values that is `devops-lab-vpc`. Other stacks read the module with the module label plus the output name:

   ```hcl
   module.network.private_subnet_ids
   module.network.vpc_id
   ```

   `first_public_cidr` is `var.public_subnet_data[0].cidr`. `second_public_cidr` is index `1`.

### Check it without AWS

```bash
cd ../08-network-module
terraform init
terraform test
```

`terraform test` plans the module with a mock AWS provider. You should see 4 passed:

- NAT off, VPC name `devops-lab-vpc`, two public subnets
- one shared NAT → count `1`
- NAT per public subnet → count `2`
- a third public subnet object → three public subnets

Read `tests/nat.tftest.hcl` if you want to see those asserts.

### Optional plan against your account

`lab.tfvars` keeps `need_nat_gateway = false`. A VPC, subnets, and an internet gateway have no hourly charge. A NAT gateway does. Apply with NAT enabled only when you will destroy it the same day. Your account also has a limit on how many VPCs it can hold.

```bash
terraform plan -var-file=lab.tfvars
```

The plan should show one VPC, two public subnets, two private subnets, one internet gateway, one public route table, one private route table, and no NAT gateway.

Then plan a third availability zone by adding this object to **both** lists in `lab.tfvars` (private and public, same zone):

```hcl
{
  name              = "c"
  cidr              = "10.20.3.0/24"      # public. Use 10.20.13.0/24 on the private list.
  availability_zone = "ap-south-1c"
  prefix            = "public"            # use "app" on the private list
}
```

The next plan should add one public subnet and one private subnet. Remove those objects again so the lab file stays at two.

NAT experiments, still as a plan:

```bash
terraform plan -var-file=lab.tfvars -var need_nat_gateway=true -var need_single_nat_gateway=true
terraform plan -var-file=lab.tfvars -var need_nat_gateway=true -var need_single_nat_gateway=false
```

The first should show one Elastic IP and one NAT gateway. The second should show two of each, and a private route table per public subnet. `output.nat_gateway_count` in the plan is `1`, then `2`.

If you apply, destroy before you stop:

```bash
terraform destroy -var-file=lab.tfvars
```

Use the same `-var` flags you applied with, so destroy sees the same counts.

### Stretch

App subnets in this module are the private list, and they receive the NAT route when NAT is on. A database subnet is a different network: its route table should have no route to the NAT gateway. If you add `database_subnet_data` later, give those subnets their own route table and leave the NAT route off it.

---

## What you should be able to explain

- Why `web-1` is state address `[0]` when you use `count`, and `["web-1"]` when you use `for_each`.
- Why a duplicate in a list would be a bad resource address, and why `toset()` drops it.
- Why a list of objects has to become a map before `for_each`.
- How `for instance in local.instance_list : instance.name => instance` chooses the key and the value.
- How `condition ? 1 : 0` turns a bool into “create it” or “leave it out”.
- How `need_nat_gateway` and `need_single_nat_gateway` become `0`, `1`, or `length(public subnets)`.
- How a dynamic `ingress` block replaces copied ingress blocks.
- How `module.network.private_subnet_ids` is the module name plus an output from `outputs.tf`.

---

## Cleanup

From any folder you applied:

```bash
terraform destroy -auto-approve
```

Part 8:

```bash
terraform destroy -var-file=lab.tfvars
```
