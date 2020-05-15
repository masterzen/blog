---
layout: single
title: Designing a keyboard from scratch - Part 2
header:
  image: /images/uploads/2020/05/header-part1.png
category:
- "mechanical keyboards"
- DIY
tags:
- design
- PCB
- electronics
- "mechanical keyboards"
---

Welcome for the second episode of this series of post about designing a full fledged keyboard from scratch. In the [episode 1]() we focused on the electronic schema of the keyboard controller.

In this episode, I'm going to cover:

* how to design the matrix
* how to assign references and values correctly
* the first steps of the PCB layout

## The matrix

Trust me, it will be probably the most boring part of this series. We're going to produce the electronic schema of 67 switches and diodes.

Since the MCU schema is taking some space in the main schema, I recommend creating a hierarchical sheet to place the matrix. This can be done by pressing the `s` shortcut and clicking somewhere in the schema. The following window should open:

![Hierarchical sheet](/images/uploads/2020/05/hierarchical-sheet.png){: .align-center style="width: 50%"}

Since we're designing the matrix, I named the sheet `matrix`.
Now with the _View_ menu -> _Show Hierarchical Navigator_ we can access our hierarchical sheet:

![Hierarchical navigator](/images/uploads/2020/05/hierarchical-navigator.png)

Clicking on the matrix will open this new schema sheet.

Let's build the matrix now. As I explained in the previous article, the matrix is the combination of one switch and a diode per key. It's cumbersome to add those components by hand for all the 67 keys, so I'm going to explain how to do it with a selection copy.

Let's first design our key cell, by adding a `SW_PUSH` and a regular `D` diode. Next wire them as in this schema:

![Matrix cell](/images/uploads/2020/05/matrix-cell.png){: .align-center style="width: 40%"}

Once done (if you also are doing the same on one of your design make sure the wires have the same size as in mine), press the `shift` key and drag a selection around the cell (wire included). This will duplicate the selection (our cell), next move the mouse pointer so that the second diode bottom pin is perfectly aligned with the first cell horizontal wire:

![Drag copy cell](/images/uploads/2020/05/matrix-drag-selection.png){: .align-center style="width: 40%"}

Then click the left mouse button to validate. Now repeat the `shift` drag selection operation on both cells at once to duplicate them:

![Drag copy cell x2](/images/uploads/2020/05/matrix-drag-selection-2.png){: .align-center style="width: 40%"}

Note that it is also possible to perform the move and place with the keyboard `arrow keys` and `enter` to validate.

Next, repeat the same with the 4 cells to form a line of 8, then a line of 16 cells, and remove the last one to form a 15 keys row. If the key rows is larger than the page, you can increase the sheet size by going to _File_ -> _Page Settings_ and change the _Paper Size_ to _A3_.

This should look like this:

![Matrix one row](/images/uploads/2020/05/matrix-one-line.png){: .align-center style="width: 65%"}

Let's add a label to the row (`Ctrl-H`):

![Matrix one row](/images/uploads/2020/05/matrix-label-row0.png){: .align-center style="width: 65%"}

Let's now do the other rows. I'm going to apply the same technique, just do a `shift` drag selection around the `row0` and move it downward so that wire of the columns connect:

![Matrix second row](/images/uploads/2020/05/matrix-row1.png){: .align-center style="width: 65%"}

And do the same for the next 3 rows, this will give this nice array of switches:

![Matrix all rows](/images/uploads/2020/05/matrix-all-rows.png){: .align-center style="width: 65%"}

Note that I have pruned the extra vertical wires of the last row with a large regular selection and pressing the `del` key. It is also possible to do the same for the right extra wire on every rows.

We need to edit all the row labels to make them `row1`, `row2`, etc. The columns also needs to be labelled. Start by adding a global label on the first column and label it `col0`. Use the shift-select trick to create a second one, then 2 extra ones, then 4 etc until all the columns are labelled.
Edit the labels so that they are labelled from `col0` to `col14`.

![Matrix labelled](/images/uploads/2020/05/matrix-labeled.png){: .align-center style="width: 65%"}

Nice, but I suspect you're wondering why there are too many keys in this matrix. We're going to eliminate some of the extraneous switches so that the wiring would look like this:

![Matrix wiring](/images/uploads/2020/05/matrix-wiring.png){: .align-center style="width: 65%"}

To eliminate the unneeded cells it's as easy as selecting their switch and diode (and as less wire as possible) with a drag selection and pressing the `del` key.

The matrix should look like this now:

![Matrix wiring 67 keys](/images/uploads/2020/05/matrix-all-wired.png){: .align-center style="width: 65%"}

Now, I'm going to reference all the switches and diodes I just placed. Since I'm quite lazy, I'll use the automatic referencing. If you want to reference switches by columns and rows (ie first switch is K00, second one K01, but first of row1 is K10, etc), you'll have to perform that manually (or write a Kicad script, or edit the `.sch` file with a text editor).

Use the _Tools_ -> _Annotate Schematics_ to open the annotation window:

![Annotation of the matrix](/images/uploads/2020/05/matrix-annotation.png){: .align-center style="width: 50%"}

Make sure to annotate only the current sheet, and to _Sort components by Y position_. Once done, the matrix diodes and switches will have a proper unique reference identifier. If you somehow failed, the same dialog can also erase all references (this is easy to make a mistake, like for instance applying references to the whole schematics, not only the current sheet).

The next step is to label each switches with their key character or name (ie K1 will be ``~`, K2 `#1`, etc). This will be easier during PCB layout to visually see which key we're laying out. To do this, let's open the _Tools_ -> _Edit Symbol Fields_.

This opens a new dialog that allows to group components by reference or value (or both) and to edit component values all at once:

![Editing Symbol Fields](/images/uploads/2020/05/matrix-edit-fields.png){: .align-center style="width: 50%"}

Open the `K1-K67` group, and start assigning the correct key names to the switches in order:

![Editing Key Values](/images/uploads/2020/05/matrix-edit-key-names.png){: .align-center style="width: 50%"}

Once done, the matrix itself shouldn't be different. The key names don't appear, because the `KEYSW` symbol doesn't show the value. Unfortunately it isn't possible to edit symbol with the _Symbol Editor_, make the value visible and reassign the symbol to all the `KEYSW`. If I want the key name to appear I will have to edit manually the 67 switches or edit the `matrix.sch` with a text editor. I chose to alter the `matrix.sch` file with `sed`. Make sure to save the schema, close it and `git commit` the file and project before doing this:

```sh
sed -i -r -e 's/^F 1 "([^ ]+)" H ([0-9]+) ([0-9]+) ([0-9]+)  0001 C CNN/F 1 "\1" H \2 \3 \4  0000 C CNN/' matrix.sch
```

Reopen the root schema, then the matrix and you should see something like this:

![Showing key names](/images/uploads/2020/05/matrix-key-names.png){: .align-center style="width: 50%"}

The matrix is now finished. Perfectionist could move the key values or diode references so that they don't collide.

The next step is to finally prepare the main schema

## Prepare the MCU schema

Using the _Tools_ -> _Annotate Symbols_, I'm going to assign references to the main sheet (and only this one). Once done, to ease laying out the MCU on the PCB, I'm going to tentatively assign rows and columns to the Atmega32U4 pins.

To do that, I need to tell you a few rules about laying out our board:

* the `D+`/`D-` signal form a differential pair. They need to be traced as directly as possible.
* there's only limited space available on the board between switches to put the MCU. Except behind the space bar where there's no switch at all.
* the connections between the MCU and the matrix should cross each others as little as possible, thus the MCU should be oriented wisely so that left columns are assigned to pins to the left of the MCU and reverse.

The physical layout of the MCU looks like this (it's called a pinout):

![Showing key names](/images/uploads/2020/05/atmega-pinout.png){: .align-center style="width: 50%"}

With this in mind, if I want to minimize the path for `D+`/`D-`, and considering that the MCU will be at the bottom part and the USB port at the top, I will have to put the `D+`/`D-` side up. This means that:

* PF0, PF1, PF4, PF5, PF6, PF7 will be on the right
* PD0, PD1, PD2, PD3, PD5 will be on the left
* PD4, PD6, PD7 on the bottom left
* PB5, PB6, PC6, PC7 on the bottom right

Which means that I can assign `col0` to `col4` to left pads, `col5` to `col7` to the bottom left, `col8` to `col11` to the bottom right and finally `col11` to `col14` to the right pads. The rows can be connected on the `PBx` pins of the top.

Of course this is an attempt that will serve as a guide during the PCB layout. There are great chances that I'll have to come back to the schema to reassign columns or rows to the MCU pins.

Here's the schema with the rows and columns connected:

![Wired Atmega32U4](/images/uploads/2020/05/atmega-pinout.png){: .align-center style="width: 50%"}

## Check connectivity

Before moving forward, I need to make sure everything is connected correctly. Kicad contains a tool called the _Electrical Rules Checker_ that can help debug the schema connectivity. It is available in the _Inspect_ menu.

When running the ERC, there shouldn't be any errors except missing power.

