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

Then use the 