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

The rest of the work will be quite tedious.