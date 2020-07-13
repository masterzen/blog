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

![All Vias types](/images/uploads/2020/05/via-types.png){: .align-center style="width: 80%"}

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

![All columns routed](/images/uploads/2020/05/pcb-route-all-cols.png){: .align-center style="width: 95%"}

Notice that I haven't connected the columns to the MCU yet.

Using the _Show local ratsnest_ function we can highlight the columns nets, and verify that the connection plan in [part 2]() is correct.

The idea was to have the columns on the extreme left or right be assigned the bottom part of the MCU (respectively left and right pads), and the center left columns (`col5`, `col6`) the left pads, the center columns `col7` a free top pad, and the center right columns `col8`, `col9` the right pads.

This gives this result:

![MCU much less mess](/images/uploads/2020/05/pcb-route-less-mess.png){: .align-center style="width: 50%"}

But before connecting the columns to the MCU, it's better to route the USB data-lines and power rails.

### USB differential pair

The `D+`/`D-` USB data lines form what is called a [differential pair](https://en.wikipedia.org/wiki/Differential_signaling). The idea is to send the signal on two wires instead of one. Traditionally a component uses `GND` as the reference for a signal in a single wire. This can be subject to EMI and noise. In a differential pair (and provided the impedance matches on both wire), the noise will affect both wire the same way. The MCU will compute the difference between the two signals to recover the correct value. While doing this, the noise will be cancelled (since it is the same on both lines). The differential pair is thus much more immune to EMI and noise than a single trace.

Thus differential pairs needs to be routed with care. Both trace needs to obey some rules

#### Respect symmetry

To conserve coupling it's best for the differential pair traces to keep their symmetry as best as possible.

![Keep symmetry](/images/uploads/2020/05/pcb-dp-symmetry1.png){: .align-center style="width: 50%"}
![Keep symmetry](/images/uploads/2020/05/pcb-dp-symmetry2.png){: .align-center style="width: 50%"}

#### Match Trace Length

The noise cancelling advantage of a differential pair works only if both signals arrive at the same time at the endpoint. If the traces have different lengths, one of the signal will arrive a bit later than the other, negating the effect. There's a tolerance though, especially since this keyboard USB differential pair will run at the USB _Full Speed_ standard (12 Mbit/s). 

It's possible to compute the time difference the signal in function of the length difference. With the _Full Speed_ standard a few centimeter difference will not incur a difference in arrival time, but this wouldn't be true with high-speed signals. It's best to keep the good practices of matching length all the time.

There's no function in Kicad to check trace length, hopefully I can use the [trace length plugin](https://github.com/easyw/RF-tools-KiCAD) to check both traces of the pair.

#### Reduce distance between traces

Obviously this will take less space on the PCB, which is good. But also the signal in a differential pair can induce a current in the ground plane below (if there's one), possibly creating a current loop generating noise. This is again less an issue with USB _Full Speed_ signals like the one this keyboard deals with.

#### Minimize number of vias

Each via adds inductance to the trace. It is usually recommended to not route those differential pairs through vias. But if vias have to be used anyway, make sure to use the same number of vias for both traces of the pair. With USB _Full Speed_ signals, adding via would probably not be detrimental, but it's better to keep those traces on the same layer as much as we can as a good habit.

#### Spacing around differential pairs

The differential pair should not be too close to other signals or other differential pairs. A good rule of thumb is to apply a spacing of 5 times the trace width (this is known as the `5W` rule).

Where the differential pair comes close to high speed signals (for instance clock traces), the spacing must be increased again (for instance 50mils). Differential pairs should also be spaced from other differential pairs to prevent cross-talk (use the same 5W rule).

#### Watch the Return Current

Spoiler alert: all circuits form a closed loop. The signal in a differential pair is a current that needs to flow back to it's source at some point. At higher frequencies, the return current will follow the lowest impedance path. This usually happens to be the closest reference plane (see below). If there's a void or a split in the reference plane, the return current will have a longer path leading to excess electro-magnetic emissions, delayed signal, etc.

#### Don't route close crystals

The differential pairs should not be routed under or near a crystal oscillator or resonator.

#### Crossing a differential pair

When a single track or another differential pair crosses (on a different layer) a differential pair, do it with an angle of > 30º and < 150º to minimize cross talk. To make it more easy target 90º intersections.

#### Do not use striplines

A [stripline](https://en.wikipedia.org/wiki/Stripline) is an layer trace embedded in a dielectric medium itself sandwiched by two copper plane. On the reverse a microstrip is a trace at the surface (not embdded).It's best to route differential pairs as microstrips.

![Striplines vs Microstrip](https://miro.medium.com/max/600/0*i-RNq6OJI1Af7eoB.){: .align-center style="width: 50%"}

#### Avoid Bends

If possible, the differential pair should never do a straight U-turn. When bending maintain a 135º angle all the time.

#### Keep away from edges

The recommendation is to keep at least 90mils between the traces and the ground plane edges.

#### Control the trace impedance

The USB 2.0 standard requires the transmission lines (ie cables and connected PCB tracks) to have a differential impedance of 90 ohms (which translate to a single line impedance of 45 ohm) +- 10%. 

Maintaining the impedance is capital to prevent high frequency signals to bounce. To perform controlled impedance routing, you need to compute the single trace width and spacing (there are calculator online or in Kicad, or with the free Saturn PCB calculator). 

It's relatively easy to control the impedance if there's a continuous ground plane not far below the tracks (so it's best to route those on 4+ layers PCB). But for a 2-layers PCB, assuming one of the layer is an uninterrupted ground plane, the trace size would have to be 38 mils spaced with 8 mils. This is because the height of the dielectric board is around 1.6 mm for a 2 layers board, whereas it is less than a 1 mm between two copper layers on the same side of the board.

Hopefully, if our traces are shorter than the signal wavelength there's no need to implement controlled impedance. With a tool like the Saturn PCB Calculator we can estimate the _USB Full Speed_ wavelength and thus our max trace length.

The USB _Full Speed_ rise time is between 4 ns to 20 ns. when injecting the worst case of 4 ns in the Bandwidth & Max Conductor Length calculator, the result is a bit more than 18 cm. Since this keyboard is currently 9.5 cm wide and the USB `D+`/`D-` will be traced as straight as possible, the differential pair  length will be well within the safety margin. Based on this, I'm going to use 10 mils as trace width and spacing.

#### Forbid stubs

Stubs should be avoided as they may cause signal reflections. For USB, this is seldom a problem as the data traces are point-to-point.

#### Want to know more?

Most of these recommendation were gleaned from [TI High-SpeedLayoutGuidelines](http://www.ti.com/lit/an/slla414/slla414.pdf?ts=1591205679084), [Silicon Labs USB Hardware Design Guide](https://www.silabs.com/documents/public/application-notes/AN0046.pdf), [Atmel AVR1017: XMEGA - USB Hardware Design Recommendations](http://ww1.microchip.com/downloads/en/AppNotes/doc8388.pdf), [Intel EMI Design Guidelines for USB Components](https://www.ti.com/sc/docs/apps/msp/intrface/usb/emitest.pdf). Refer to those documentation for more information.

#### Routing

Now let's apply this knowledge to this keyboard. First I need to prepare the USB connector data lines since there are 4 pads for the two datalines, they need to be connected together:

![USB datalines connector](/images/uploads/2020/05/pcb-route-prepare-usb-connector.png){: .align-center style="width: 50%"}

Use the _Route_ &rarr; _Differential Pairs_ feature and start laying out the traces from the connector. Uh oh, an error pops-up:

![Differential Pair error](/images/uploads/2020/05/pcb-dp-error.png){: .align-center style="width: 50%"}

To be able to route a differential pair, Kicad requires its nets should obey a specific naming. Net names should end up in `P`/`N` or `+`/`-`, which is not the case here. The USB pads nets have no name, as they acquire their name only after the impedance matching resistors. To correct this, I just need to assign name to the wires in the schema editor:

![Adding names](/images/uploads/2020/05/usb-c-dp-dn-names.png){: .align-center style="width: 50%"}

And finally using _Update PCB from schematics_, I can start routing the USB data-lines (using the _Route_ &rarr; _Differntial pair_ function):

![Routing the USB data-lines](/images/uploads/2020/05/pcb-route-usb-dp-goind-down.png){: .align-center style="width: 50%"}

Uh oh, it looks like I made another mistake while placing the components in [part 2](), the PRTR5V0U2X is reversed:

![Incorrect placement](/images/uploads/2020/05/pcb-route-dp-issue.png){: .align-center style="width: 50%"}

I made the same error as for the MCU (those components are laid on the back but we see them through the top, so everything is mirrored). It's easy to correct this by rotating the PRTR5V0U2X and moving around the fuse.

The next step is to connect the differential pair to the PRTR5V0U2X. Unfortunately Kicad is not very smart when connecting a differential pair to pads. It's better to stop drawing the differential pair, switch to single track routing mode and connect the pads to the differential pairs. Since it's important to minimize stubs, it's best to uncouple a bit the differential pair to connect it to pads, like this:

![PRTR5V0U2X connection](/images/uploads/2020/05/pcb-route-PRTR5V0U2X.png){: .align-center style="width: 50%"}

Then, the differential pair can be routed to the pair of impedance matching resistors:

![USB D+/D-](/images/uploads/2020/05/pcb-route-dp-to-resistors.png){: .align-center style="width: 50%"}

To connect the resitors to the MCU with a differential pairs, it's easier to start form the MCU by using the _Route_ &rarr; _Differential Pair_ function and connect it to the resistors:

![To the MCU](/images/uploads/2020/05/pcb-route-dp-to-mcu.png){: .align-center style="width: 50%"}

Now, I can check both trace length with the _Measure Length of Selected Tracks_ plugins. To do that, select one trace of the pair, and use the `u` shortcut to select it fully. In the case of this keyboard, I got 70.05mm for the left traces and 69.90 mm for the right one. This is small enough to not try to optimize it.

The final routing of this differential pair looks like this:

![USB D+/D-](/images/uploads/2020/05/pcb-route-db-final.png){: .align-center style="width: 50%"}

### Routing switch rows

The first step is to connect the right switch pad (#2) to its diode anode for every switch:

![Switch rows](/images/uploads/2020/05/pcb-route-sw-row-diode.png){: .align-center style="width: 50%"}

Then connect all cathodes together with a track forming the row. Draw a straight line first:

![straight row](/images/uploads/2020/05/pcb-route-row-straight.png){: .align-center style="width: 50%"}

Then use the `d` shortcut to produce a more appealing form by dragging the track toward the bottom:

![better row](/images/uploads/2020/05/pcb-route-row-better.png){: .align-center style="width: 50%"}

Do that for all the switches, but do not connect the rows to the MCU, nor cross the USB differential pair yet, because there will be some choices to be made and experimentation.

### Routing the crystal oscillator

Routing the crystal oscillator is easy as there are few tracks and components. But the crystal generates a square signal at 16 MHz. A [square signal](https://en.wikipedia.org/wiki/Square_wave#Fourier_analysis) is the combination of a lot of powerful harmonics in the frequency domain. Those are an issue for EMC, so special care has to be applied for placement and routing of the clock circuits.

The first rule is that we have to make the `XTAL1` and `XTAL2` trace as short as possible, which means the crystal has to be as close as possible to the MCU, this is in order to minimize parasitic capacitance and interference. For the same reason, avoid using vias in the crystal traces.

The second rule is that we have to space other signals as much as possible to prevent the clock noise to be coupled to other traces (but also the reverse). To prevent as much as possible this effect, it is recommended to add a GND guard ring around the cristal traces.

The main problem with crystal oscillators is the return current. Every electrical circuit is a loop, so the current that gets in the crystal, needs to go back to somewhere for the crystal oscillator to work. This return current is also a square signal containing high frequency harmonics. The problem is that the loop formed to return the current is a kind of antenna. If it is large, it will radiate a lot of EMI which we want to minimize (and also if it's an antenna it will be susceptible to external emission which we also want to minimize). I've seen design with a general ground and vias connected to the crystal GND: in such case this pour becomes a nice patch antenna. If we were to design this keyboard with a ground pour, the one under the crystal oscillator should be an island not connected to the rest of the ground pour to prevent radiating everywhere and to make sure the current return loop is as small as possible. In fact it's even better to add a ground pour guard ring on the same layer as the crystal (the loop formed in this case will be shorter than crossing the 1.6mm pcb).

The 22pF load capacitors should be placed as close to the crystal as possible.

Let's start by connecting the crystal oscillator to the MCU (both `XTAL1`, `XTAL2` and `GND`):

![Crystal](/images/uploads/2020/05/pcb-route-xtal.png){: .align-center style="width: 50%"}

Then using the _Add Filled Zone_ tool (select the GND net), we're going to draw a rectangle around the crystal:

![Crystal layer guard ring](/images/uploads/2020/05/pcb-route-xtal-gnd-guard1.png){: .align-center style="width: 50%"}

![Crystal layer guard ring](/images/uploads/2020/05/pcb-route-xtal-gnd-guard2.png){: .align-center style="width: 50%"}

If we want to add a copper ground island in the other layer (`F.Cu`), we can do this easily by right clicking one of the control point of the filled zone we just added and use _Zones_ &rarr; _Duplicated Zones onto layer_, then select `F.Cu`. This zone will not be connected to anything, so we have to add a few vias:

![Crystal layer F.Cu zone](/images/uploads/2020/05/pcb-route-xtal-fcu-zone.png){: .align-center style="width: 50%"}

This isn't complete, we should probably extend the underlying zone under the `XTAL1` and `XTAL2` MCU zone. First select the `F.Cu` layer, then right-click on the _Create Corner_ function to add a control point. Do it againg and extend the zone under the `GND`, `XTAL1` and `XTAL2` pads:

![Crystal layer ground pour](/images/uploads/2020/05/pcb-route-xtal-extended-zone.png){: .align-center style="width: 50%"}

### Routing the power rails

The next thing to do is to power the active components. It's always best to route power and ground traces before the signal traces. The signal traces can be moved around, they are not critical and are narrower than power traces.

Hopefully there's only one active component this keyboard the MCU (keyboards with leds, underglow, rotary encoder might have more than one active component). The power comes from the USB port delivered directly by the host.

The first step is to wire the USB Type-C power traces (and also the `CC1` and `CC2`). There are several possibilities, depending on where we want the `+5V` and `GND` to come from (since there are 2 pads with those nets on the USB connector to support both orientations).

![USB-C Power](/images/uploads/2020/05/pcb-route-usb-power.png){: .align-center style="width: 50%"}

Notice that I haven't yet wired `GND`. Then I can route `+5V` down to the MCU. I deliberately spaced the trace from the `D+`/`D-` USB differential pair to prevent it to couple into the power trace (remember the 5W rule from earlier?)

![USB-C Power Down](/images/uploads/2020/05/pcb-route-usb-5v-down.png){: .align-center style="width: 50%"}

This power trace needs to deliver power to all the `VCC` pads of the MCU. The best way to do that is to use a grid system around the MCU on the other layer. Do not close the loop, that would be quite bad.

![PCB MCU Power](/images/uploads/2020/05/pcb-route-mcu-power.png){: .align-center style="width: 50%"}

At the same time I connected the `GND` pads together with a kind of badly shaped star. I'll replace it with a local ground pour, but if not, the star would have to be redesigned to have less acute angles. There's an interest in having a ground pour behind the MCU (on the same layer), it will help conduct the generated heat and serve as a poor's man radiator.

Even though I'll use a ground pour on the front and back layer, it's better to materialize the GND trace to the MCU. If possible I'll come back and simplify the routing when those pour will be laid out. Meanwhile the PCB would still be functional:

![USB-C GND Down](/images/uploads/2020/05/pcb-route-usb-gnd.png){: .align-center style="width: 50%"}

Then route the `GND` trace close to the `+5V` one down to the MCU:

![PCB MCU GND](/images/uploads/2020/05/pcb-route-mcu-gnd.png){: .align-center style="width: 50%"}

Make sure to not create any `GND` loops.

### Connect the matrix

I'm going to connect the matrix. This will also allow to check if the projected connection scheme on the MCU will work or not.

I'm used to start from the MCU and progress towart the matrix rows and columns. A good way to do that, is to start some kind of bus from the MCU pads going globally in the direction of the rows or columns to connect like this:

![Routing matrix bus out of the MCU](/images/uploads/2020/05/pcb-route-mcu-matrix.png){: .align-center style="width: 50%"}

While doing that, it appears that there is a small issue on the left part of the MCU. `row4` has been placed right between `row1` and `row3`:

![row4 issue](/images/uploads/2020/05/pcb-route-mcu-row4-issue.png){: .align-center style="width: 50%"}

Ideally, `row4` should be on the MCU pad 38 because it is to be connected directly at the bottom, while `row1` and the other rows have to be connected on the left or middle part of the PCB.

Going back to the schema, it is easy to swap `row4` and `row1`:

![MCU swap row4 and row1](/images/uploads/2020/05/mcu-row4-fix.png){: .align-center style="width: 50%"}

Routing again a bit more the left rows and columns, and it looks like it's not yet perfect. There's a conflict between `col5`, `col6` and `row4`:

![conflict with `row4`](/images/uploads/2020/05/pcb-route-conflict-row4.png){: .align-center style="width: 50%"}

It seems much more natural to have `row4` at the bottom on pad 36, then `col5` and `col6` (from the bottom to up), this prevents crossing those three tracks:

![Less intersection around `row4`](/images/uploads/2020/05/pcb-route-conflict-row4.png){: .align-center style="width: 50%"}

To connect the left columns (from `col1` to `col5`), the more appealing way to do that is to group the traces as a kind of bus that connects to a pad on the last column row. Since the columns are connected on the `F.Cu` layer, it makes sense to convert the `B.Cu` traces out of the MCU with vias:

![Left columns out of the MCU](/images/uploads/2020/05/pcb-route-mcu-left-cols.png){: .align-center style="width: 50%"}

If all the traces follows the same model, it can be visually appealing:

![Left columns distributions](/images/uploads/2020/05/pcb-route-left-columns.png){: .align-center style="width: 50%"}

Now let's hook the right columns (`col8` to `col14`). Once again the idea is to group the traces together, first on `B.Cu` then switch to `F.Cu` to be able to cross the `B.Cu` `row4`:

![Right columns out of the MCU](/images/uploads/2020/05/pcb-route-mcu-right-cols.png){: .align-center style="width: 50%"}

While doing that, make sure to not route the tracks too close to the border (or check the manufacturer clearance first). Then, keep going all the bus to their respective columns with the same kind of forms:

![Left columns distributions](/images/uploads/2020/05/pcb-route-right-columns.png){: .align-center style="width: 50%"}

And finally, the last part of the matrix to be connected are the remaining rows (from `row0` to `row3`, as `row4` is already connected). There are multiple solutions (in fact any column in-between would work). But once again, I'm afraid I'll have to rearrange the MCU pads:

![MCU rows mess](/images/uploads/2020/05/pcb-mcu-route-rows-mess.png){: .align-center style="width: 50%"}

There's `row3` at a very short distance from pad 1, so it makes sense to connect it there. I'm going to connect the rows from the left part and down between `row3` et `row4` as this will minimize the number of crossings:

![Top left rows](/images/uploads/2020/05/pcb-route-topleft-rows.png){: .align-center style="width: 50%"}

But then arriving to the MCU it's clearly not in the right order:

images/uploads/2020/05/pcb-route-mcu-rows-mess2.png

Let's rearrange the rows in top down order in the schematic:

images/uploads/2020/05/mcu-reorder-rows.png

And after updating the PCB from the schematic, I can finally connect the remaining rows:

images/uploads/2020/05/pcb-route-mcu-rows-in-order.png

### Last remaining bits

I still need to connect the reset button and the ISP header. Once everything has been done, it's just a matter of finding the natural location (close to their assigned pads) and orientation (to minimize tracks crossings):

images/uploads/2020/05/pcb-route-mcu-reset-isp.png

I had to divert `col8` around the reset button and isp because it was too much in the way, but in the end it was possible to connect those components without too much vias.

### Checking everything is right

Before going any further, I need to check the routing is correct. It's easy to forget a connection or to cross two traces without noticing. Hopefully, Kicad has the _Design Rules Checker_ feature which allows to check all those mistakes, but also the manufacturer clearances.

It can give the following errors:

images/uploads/2020/05/pcb-route-unconnected-col5.png

Thankfully this one is easy to fix.

### Making the board a bit nicer

Let's have a 3D look of the board to see how it looks:

If you do that you'll notice that the following things:

* switch pads are not appearing on the front face
* the switch key name is not appearing anywhere
* same for the ISP header

I will have to edit the footprints to remove the soldermask on the top layer pads, but also display the switch value at least on the back.

Open the footprint editor, locate the `Alps-1U` footprint and select the left pad:

images/uploads/2020/05/footprint-edit-alps.png

Edit the pad properties (`e` shortcut), and make sure that both `F.Mask` and `B.Mask` are checked:

images/uploads/2020/05/footprint-alps-edit-pad.png

Do the same for the second pad. Then place a new text near the top of the footprint enter `%V` in the `Text` entry box (that will reflect the component value, which happens for our switch to be the key name or symbol), chose the `B.SilkS` layer and check the `mirrored` checkbox:

images/uploads/2020/05/footprint-bsilk-key-name.png

If you also want the key name to be displayed on the front, add another text but chose the `F.SilkS` layer and unselect the `mirrored` checkbox.

Save the footprint, then do the same for the other footprint sizes.

Once done, the PCB needs to be updated. In the PCB editor, select the _Tools_ &rarr; _Update Footprints from Library_. In the dialog box, select all components with reference `K??`, check the three checkboxes so that all the text components will be updated and press _update_:

images/uploads/2020/05/pcb-update-switch-footprints.png

Check the 3D Viewer to see the rendered silkscreen on the front and back:

images/uploads/2020/05/rendered-pcb-front.png
images/uploads/2020/05/rendered-pcb-back.png

Unfortunately, we did this on ai03 library so the modification can't be really committed, as its library was added as a git submodule. Hopefully, I did the modifications in a fork of ai03 library (sorry, only Alps, no MX), so instead of adding ai03 submodule, you can add mine: `git@github.com:masterzen/MX_Alps_Hybrid.git`. And if you followed this article from the beginning, you can update the submodule with mine (see the [How to change git submodule remote](https://stackoverflow.com/questions/913701/how-to-change-the-remote-repository-for-a-git-submodule)).

But wouldn't it be a really PCB without at least a few silkscreen art?

The idea is to draw a vectorial logo (for instance in Adobe Illustrator or Inkscape), then import it as a footprint in Kicad.

Since this is an Alps based board, I thought it would be nice to have a mountain as the logo. Since I'm not a graphist, I downloaded a nice mountain wireframe in SVG from the Creative Commons Clipart website, loaded in Inkscape and added the keyboard name (I had to rework the SVG to fix a few issues from there to there). Since this will go in the `F.SilkS` layer, I named the Inkscape layer `F.SilkS`:

images/uploads/2020/05/inkscape-logo.png

If you want to add text, make sure to convert the text to paths (with the _Object to path_ inkscape function), otherwise it won't be imported.

Save the file as _Inkscape SVG_. Kicad doesn't yet support import SVG files directly so we first have to convert the vector file to a format that Kicad can read. There are several possibilities:

* save a DXF from Inkscape and import it in Kicad. This works fine, but then any filled zone will be lost, and you need to recreate them in Kicad which can be painful.
* use a converter tool like [svg2mod](https://github.com/svg2mod/svg2mod) or [svg2shenzen](https://github.com/badgeek/svg2shenzhen).

I tried both method, and I won't recommend the first one, so I'm going to show how to convert the SVG to a format Kicad can understand.

I wasn't able to make the [svg2shenzen](https://github.com/badgeek/svg2shenzhen) Inkscape extension work correctly on my mac, so I resorted to using [svg2mod](https://github.com/svg2mod/svg2mod) which worked fine.

First install this tool with `pip3 install git+https://github.com/svg2mod/svg2mod`. Then run it on the svg file:

```
% svg2mod -i logo.svg -o ../local.pretty/logo -f 0.85 --name logo
Parsing SVG...
No handler for element {http://www.w3.org/2000/svg}defs
No handler for element {http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd}namedview
No handler for element {http://www.w3.org/2000/svg}metadata
transform: matrix [4.9686689, 0.0, 0.0, 5.4800484, -251.10361, -536.90405]
transform: matrix [0.05325035, 0.0, 0.0, 0.0482812, 50.5374, 97.974326]
transform: matrix [0.05325035, 0.0, 0.0, 0.0482812, 50.5374, 97.974326]
transform: matrix [0.05325035, 0.0, 0.0, 0.0482812, 50.5374, 97.974326]
transform: matrix [0.05325035, 0.0, 0.0, 0.0482812, 50.5374, 97.974326]
transform: matrix [4.9451996, 0.0, 0.0, 6.2660263, 266.42682, -668.87041]
Found SVG layer: F.SilkS
Writing module file: ../local.pretty/logo.kicad_mod
    Writing polygon with 5 points
    Writing polygon with 7 points
    Writing polygon with 22 points
    Writing polygon with 161 points
    Inlining 1 segments...
      Found insertion point: 0, 6
    Writing polygon with 22 points
    Writing polygon with 21 points
    Writing polygon with 28 points
    Inlining 1 segments...
      Found insertion point: 0, 0
    Writing polygon with 84 points
    Writing polygon with 31 points
```

This produces a Kicad footprint, which we can view in the footprint editor:

images/uploads/2020/05/footprint-front-logo.png

Note that I created it in the `local` library I used earlier.

Then place this footprint (`o` shortcut) on the PCB:

images/uploads/2020/05/pcb-front-logo.png

Note that it isn't possible to resize a footprint. To be able to rezise it you need to regenerate the footprint and change the resizing factor in `svg2mod` (the `-f` argument in the command above).

Let's also do a small back-side logo. With the exact same logo, I can apply a flip in Inkscape, rename the layer to `B.SilkS`, and finally save the SVG to another file. When converting the small logo to a Kicad footprint, I used a very small `-f` factor (0.15 exactly). I can again place it on the PCB:

images/uploads/2020/05/pcb-small-back-logo.png

Note that I've also added a small copyright and version number text on the `B.SilkS` layer.

### The result

Here's the result so far:

images/uploads/2020/05/rendered-front-with-logo.png

And the back:

images/uploads/2020/05/rendered-back-with-logo.png

### To ground fill or not

I've seen a lot of 2-layers keyboard PCB design that use ground fills on both faces. I believe the attempt is here to reduce EMI. I tend to think it is a counter productive to have such ground fills (or pour). First those won't reduce EMI, only proper bypass/decoupling capacitors, conscious routing of high frequency trace (to minimize loops area), or using a ground grid scheme can help reduce EMI. Some will say that it helps for heat dissipation, or that they are forced to use ground fills for manufacturing reasons or that they paid for the copper, so better use all of it.

Don't get me wrong, on a multilayer PCB, having uninterrupted ground planes is essential to reduce EMI. But on 2-layers PCB, it will be hard to have an uninterrupted ground (hence we talk about ground fill, not plane). Any slot in the ground fill that would interrupt a return current will just make an antenna. A ground fill might reduce cross-talks between traces, but it can also be an antenna if it's to thin and long. So if you want to add a ground fill, just take care of doing it properly.

That's the reason we routed GND as a trace earlier, at least there's an uninterrupted return path for the current. We could stop the design here and produce the board as is, it would definitely work.

Still for the exercise, I'm going to try to add a ground fill on both faces, but doing so correctly (or at least trying :).

Let's see how we can add a ground pour. In kicad use the _Add Filled Zone_ tool and draw a large rectangle in the `B.Cu` layer around the whole PCB. To ease drawing, it's better to use a 20 mils grid settings:

images/uploads/2020/05/pcb-route-ground-pour-start.png
images/uploads/2020/05/pcb-ground-pour-keep-going.png
images/uploads/2020/05/pcb-route-ground-pour-fcu-result.png

This is far from being perfect, because it merged the crystal oscillator ground island we designed earlier. I have to add a keep out zone to disconnect the island. This can be done by right-clicking on the ground zone and choose _Zones_ &rarr; _Add a Zone Cutout_, then draw a rectangle around the crystal oscillator ground zone, spaced by 20 mil:

images/uploads/2020/05/pcb-route-crystal-cutout.png

Next, let's duplicate the same copper fill on the other side by going again in the zone contextual menu and choosing _Duplicate Zone onto layer_ and chose `GND` on `F.Cu`:

images/uploads/2020/05/pcb-route-duplicate-pour-fcu.png

Note that when creating a zone, make sure to select the _Pad connection_ _thermal relief_ option. A set of clearance parameter that works fine is 6 mils for the regular clearance, 10 mils of minimum width and 20 mils for both thermal clearances. The thermal clearance and pad connection are very important otherwise hand-soldering the pcb will be very difficult as the ground fill copper would dissipate the soldering iron heat and the solder might be difficult to flow. If the pcb is to be assembled at a factory then it wouldn't be an issue.

Let's look what we can do to make the copper fill better. First we have to make sure the copper fills are properly grounded by stitching vias from there to there. This will reduce the plane capacitance, but that's not an issue since we have plenty of decoupling capacitors and reduce the potentiality of any part becomming an antenna. Place a few vias from there to there or use the Via Stitching kicad plugin to do that. Here's an example with the Via Stitching plugin with a grid of 32mm (no need to make a swiss cheese):

images/uploads/2020/05/pcb-route-stitching-vias.png

There are still some issues. If the return current goes into the `F.Cu` ground fill back to the USB connector, the path of least impedance would cross several horizontal traces. That's were we could have an EMI issue. 






