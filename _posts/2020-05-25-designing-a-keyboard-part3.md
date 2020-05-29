---
layout: single
title: Designing a keyboard from scratch - Part 3
header:
  image: /images/uploads/2020/05/header-part2.jpg
category:
- "mechanical keyboards"
- DIY
tags:
- design
- PCB
- electronics
- "mechanical keyboards"
---

Welcome for the third episode of this series of posts about designing a full fledged keyboard from scratch. The [first episode](/2020/05/03/designing-a-keyboard-part-1/) focused on the electronic schema of the keyboard controller, the [second one](/2020/05/03/designing-a-keyboard-part-2/) was on the components layout. In this one I'll cover:

* how to route the matrix, the MCU, the USB datalines
* merits of doing a ground pour
* producing the needed files for manufacturing

## The Art of Routing

Routing is the process for connecting the various pins and pads of the circuit with copper traces. There are things that can and can't be done while doing this, for instance several circuits have specific constraints for EMI, impedance matching, etc.

In the previous episode I chose a two copper layers. The switches will be placed on the front layer, and because they are through-hole components they're being soldered on the back. All the rest of the components are laid out on the back of the board.

In the part 2 of this posts series, I designed the matrix schema, with non intersecting rows and columns. This means that if we were to route the matrix on the same PCB face we'd had an issue: all rows would collide with the columns.

Hopefully, thanks to the two layers, we can route the columns on one side and the rows on the other side. But there are other components to connect: the USB Type-C connector (and the ESD protection circuits), the MCU, the reset push-button, etc.

The USB Type-C connector is on the back layer at the top of the board, the MCU is also on the back layer but at the bottom. That means there are a few tracks to route vertically like the columns.

Inevitably some traces will intersect other traces. In such case it is possible to switch the trace to another layer by placing a [_via_](https://en.wikipedia.org/wiki/Via_(electronics)). A via is an electrical connection between two layers. The trace can then extend from one layer to another. Basically it is a hole that is metal plated to be able to conduct electricity. Note that there are different kinds of via, depending on if they cross the whole board or only some layers. In the case of two layers PCB, it will be through-hole vias.

![All Vias types](images/uploads/2020/05/via-types.png){: .align-center style="width: 80%"}

With a pair of vias in series the trace can jump to the other side and come back to its original side.

Another important thing to know is that a through hole pad (like the switch ones, but this is valid for any through-hole components) is available on both layers. This means a trace can piggy-back a switch pad to switch layer:

![TH Pad to switch layer](/images/uploads/2020/05/pcb-route-switch-at-pad.png){: .align-center style="width: 50%"}

To prevent via abuse, the routing needs to take advantage of the number of layers. So for instance I can route the columns on the front layer, and the rows on the back layer. 

![Routing columns on front](/images/uploads/2020/05/pcb-route-columns-top.png){: .align-center style="width: 50%"}

But it is also possible to do the reverse:

![Routing columns on back](/images/uploads/2020/05/pcb-route-columns-back.png){: .align-center style="width: 50%"}

I was forced to use vias to jump other the columns `col1`. I tried two possibilities, using vias only for the minimal jump or using vias on the pad. Notice how both seems inelegant. Putting a via on a pad is also [not a good idea](https://electronics.stackexchange.com/questions/39287/vias-directly-on-smd-pads) unless the manufacturer knows how to do plugged vias. This can be needed for some high-frequency circuits where the inductance needs to be reduced. This isn't the case of this very low speed keyboard, so I'll refrain abusing vias.

### Routing matrix columns

Let's route the columns. Start from the top left switch (or any other switch), then activate trace routing by pressing the `x` shortcut. Make sure that the `F.Cu` layer is active. If it's not the case you can switch from one layer to another by pressing the `v` shortcut. Caution: if you press `v` while routing a track, a via will be created. To start routing, click on the `GRV` left pad, then move the mouse down toward the `TAB` switch left pad (follow the net yellow highlighted line):

![Routing first column](/images/uploads/2020/05/pcb-route-first-step.png){: .align-center style="width: 50%"}

Notice that while routing a specific net, this one is highlighted in yellow, along with the pads that needs to be connected.

Keep going until you reach the next pad, and then click to finish the trace. Notice that the route is automatically bent and oriented properly. This is the automated routing:

![Routing 2nd step](/images/uploads/2020/05/pcb-route-second-step.png){: .align-center style="width: 50%"}

Keep going until all columns have been routed. Sometimes the trace is not ideally autorouted by the automated routing system. In this case, the best is to select the segment and use the _Drag Track Keep Slope_ (shortcut `d`) to move the trace. For instance this trace pad connection could be made better :

![Not ideally oriented trace](/images/uploads/2020/05/pcb-route-bad-trace.png){: .align-center style="width: 50%"}

Dragging the track with `d` until I eliminated the small horizontal trace:

![better trace](/images/uploads/2020/05/pcb-route-better-trace.png){: .align-center style="width: 50%"}

When all the columns are completed it looks like this:

![All columns routed](/images/uploads/2020/05/pcb-route-all-cols.png){: .align-center style="width: 50%"}

Notice that I haven't connected the columns to the MCU yet. Notice also that I failed attributing the matrix columns to MCU pads, as the left columns are connected to the right pads of the MCU. I'm going to fix this now

Using the _Show local ratsnest_ function we can highlight the columns nest:

![MCU mess](/images/uploads/2020/05/pcb-route-mcu-mess.png){: .align-center style="width: 50%"}

Here's the battle plan to clear the mess:

* move `col7` to pad `8`, since it's closer
* move left `row0` and `row1`
* move `col4` to `col0` to bottom pads `32` to `28`
* move `col5` and `col6` to left pads `37` and `36`
* move `col12` to `col14` to bottom pads `25` to `27`
* move `col8` to `col11` to right pads `19` to `22`

The global idea is to have the columns on the extreme left or right be assigned the bottom part of the MCU (respectively left and right pads), and the center left columns (`col5`, `col6`) the left pads, the center columns `col7` a free top pad, and the center right columns `col8`, `col9` the right pads.

Here's the new schema:

![MCU mess](/images/uploads/2020/05/mcu-schema-reassigned-pins.png){: .align-center style="width: 50%"}

And after using _Tools_ &rarr; _Update PCB from schematic_, the MCU mess is a bit better:

![MCU much less mess](/images/uploads/2020/05/pcb-route-less-mess.png){: .align-center style="width: 50%"}

But before connecting the columns to the MCU, it's better to route the USB datalines and power rails

The thing we know is that the USB data-lines form a differential pair. To route this pair, it is recommended to 

