#import "@preview/cetz:0.5.3": canvas
#import "@preview/cetz-plot:0.1.4": plot

#set document(
  title: [Why the Average Lies: Survival Analysis for Restricted Network Infrastructure],
  author: "Ivan Palii",
)
#set page(paper: "a4", margin: (x: 3cm, y: 2.8cm), numbering: "1")
#set text(font: "New Computer Modern", size: 12pt)
#set par(justify: true, leading: 0.7em, spacing: 1.1em)
#set heading(numbering: "1.")
#show heading: it => block(above: 1.8em, below: 0.9em, it)

// Title block
#align(center)[
  #text(size: 24pt, weight: "bold", hyphenate: false)[Why the Average Lies]
  #v(0.4em)
  #text(size: 14pt, style: "italic", hyphenate: false)[
    Survival Analysis for Restricted Network Infrastructure
  ]
  #v(1.2em)
  Ivan Palii \
  Dublin City University \
  November 2026
]

#v(1.5em)

// Summary
#block(
  inset: (x: 1.2em, y: 1em),
  stroke: (left: 2pt + luma(150)),
)[
  *Summary.* How long does a server survive in a network where servers get blocked? The obvious answer, the average lifetime, is misleading, because some servers are still reachable when observation ends. We show this on a small synthetic example and then use the Kaplan–Meier estimator, which makes use of every server, including the ones still alive. A Greenwood confidence band shows how far the resulting curve can be trusted: with only ten servers, not very far.
]

= The question

Network infrastructure is never static, especially in regions where internet access is restricted. Servers in such networks are regularly blocked and stop doing their job. Sooner or later, every server is affected, and the operator has to replace it.

For a system administrator, the key question becomes how long their servers survive. The answer shows how resilient the system is to blocking. How can we measure how long a server stays reachable before it is blocked? It sounds like a simple statistical problem, but it runs deeper. This article shows why standard methods fail here and what to use instead.

= Why the average fails

Suppose we observe ten servers for 30 days (a synthetic example). At the end of the period, 6 of them are blocked and 4 are still reachable. The blocked servers were lost on these days: one on day 3, one on day 5, two on day 10, one on day 18, and one on day 25.

Let's try the arithmetic mean first. We take the six blocked servers, sum their lifetimes, and divide by 6:
#v(0.25em)
$
  (3+5+10+10+18+25)/6 = 11.83 approx 12 "days"
$
#v(0.25em)
So the average lifetime looks like about 12 days. But we made a mistake: we ignored the four servers that are still reachable. These are exactly the longest-lived ones, so the result is too low.

Let's include them, counting each as 30 days:
#v(0.25em)
$
  (3+5+10+10+18+25+30+30+30+30)/10 = 19.1 approx 19 "days"
$
#v(0.25em)
This is a different mistake. We do not know when those four servers will be blocked: they will live longer than 30 days, so counting them as exactly 30 is wrong. The true mean is certainly higher than 19.1, and we cannot say by how much. That is the core of the problem.

A dataset where the event of interest (here, blocking) has not yet happened for some objects is called *censored*. The arithmetic mean cannot handle such data. We need a method that uses all the objects, including the information "still reachable on day 30".

= The Kaplan–Meier estimator

Instead of taking one average, we ask a question on every day when some server was blocked: of the servers that are still in the study, what share survived this day? Then we multiply these shares. This way, servers that are still reachable work in our favor: they stay in the count until the observation ends, and we never pretend they were blocked.

We use the following notation:
#v(0.25em)
- $t_i$: a day on which at least one server was blocked;
- $n_i$: the number of servers still reachable and still observed just before day $t_i$;
- $d_i$: the number of servers blocked on day $t_i$;
- $hat(S)(t)$: the estimated probability that a server is still reachable on day $t$.
#v(0.25em)
The Kaplan–Meier estimator is then:
#v(0.25em)
$
  hat(S)(t) = product_(t_i <= t) (1 - d_i / n_i)
$
#v(0.25em)
At every step we multiply the previous value by the share of servers that survived that day.

#block(sticky: true)[Let's apply this formula to our set of servers and make a table.]

#figure(
  table(
    columns: 5,
    table.header([*Day*], [*$n_i$*], [*$d_i$*], [*$1 - d_i/n_i$*], [*$hat(S)$*]),
    [3], [10], [1], [$9/10$], [$9/10$],
    [5], [9], [1], [$8/9$], [$4/5$],
    [10], [8], [2], [$3/4$], [$3/5$],
    [18], [6], [1], [$5/6$], [$1/2$],
    [25], [5], [1], [$4/5$], [$2/5$],
  ),
  caption: [Kaplan–Meier calculation for the ten servers.],
)

No server is blocked after day 25, so the curve stays flat at $2/5 = 0.4$ until day 30. The four servers that are still reachable stay in the count until the end of the observation period, but they never produce an event.

How to read the result: we estimate that about 40% of servers are still reachable after 30 days. The *median* survival time, the first day when the curve reaches 0.5 or below, is day 18.

Compare this with the earlier averages. Both 12 and 19 days were too low. The mean cannot even be estimated here, because the curve never reaches zero: four servers are still alive. The median can be, and it gives a meaningful answer: half of the servers survive about 18 days.

#figure(
  canvas({
    plot.plot(
      size: (10, 6),
      x-label: [Day],
      y-label: [$hat(S)(t)$],
      x-min: 0, x-max: 31,
      y-min: 0, y-max: 1.05,
      x-tick-step: 5,
      y-tick-step: 0.2,
      {
        // step curve, vertices given explicitly
        plot.add((
          (0, 1), (3, 1), (3, 0.9), (5, 0.9), (5, 0.8),
          (10, 0.8), (10, 0.6), (18, 0.6), (18, 0.5),
          (25, 0.5), (25, 0.4), (30, 0.4),
        ), style: (stroke: rgb("#1f77b4")))
        // cross: four servers are still reachable on day 30
        plot.add(((30, 0.4),), mark: "x", style: (stroke: none), mark-style: (stroke: red))
        // median
        plot.add-hline(0.5, style: (stroke: (dash: "dashed", paint: gray)))
        plot.add-vline(18, style: (stroke: (dash: "dashed", paint: gray)))
      },
    )
  }),
  caption: [Kaplan–Meier curve for the ten servers. The cross marks four servers still reachable at day 30; dashed lines mark the median (day 18).],
)

= How far to trust the curve

The curve looks precise, but it is built from only ten servers. A different set of ten servers would give a different curve, because every single server changes it. So we cannot take the curve at face value. What we can do is measure how uncertain it is.

The Greenwood formula estimates how uncertain the curve is at each point:
#v(0.25em)
$
  hat("Var")(hat(S)(t)) = hat(S)(t)^2 sum_(t_i <= t) d_i / (n_i (n_i - d_i))
$
$
  "SE" = hat(S)(t) sqrt(sum_(t_i <= t) d_i / (n_i (n_i - d_i)))
$
$
  hat(S)(t) plus.minus 1.96 dot "SE"
$
#v(0.25em)
*Step 1.* For each blocking day, calculate $d_i / (n_i (n_i - d_i))$:
$
  "day 3:" & quad n = 10, d = 1 --> 1/90 \
  "day 5:" & quad n = 9, d = 1 --> 1/72 \
  "day 10:" & quad n = 8, d = 2 --> 1/24 \
  "day 18:" & quad n = 6, d = 1 --> 1/30 \
  "day 25:" & quad n = 5, d = 1 --> 1/20
$
#v(0.25em)
*Step 2.* Accumulate the sum up to each day:
$
  "day 3:" & quad sum_(t_i <= t) d_i / (n_i (n_i - d_i)) = 1/90 \
  "day 5:" & quad sum_(t_i <= t) d_i / (n_i (n_i - d_i)) = 1/40 \
  "day 10:" & quad sum_(t_i <= t) d_i / (n_i (n_i - d_i)) = 1/15 \
  "day 18:" & quad sum_(t_i <= t) d_i / (n_i (n_i - d_i)) = 1/10 \
  "day 25:" & quad sum_(t_i <= t) d_i / (n_i (n_i - d_i)) = 3/20
$
#v(0.25em)
#block(sticky: true)[*Step 3.* Compute the standard error and the 95% band:]
#figure(
  table(
    columns: 6,
    table.header([*Day*], [*$hat(S)$*], [*Sum*], [*SE*], [*Lower*], [*Upper*]),
    [3],  [0.900], [$1/90$],  [0.095], [0.714], [1.000],
    [5],  [0.800], [$1/40$],  [0.126], [0.552], [1.000],
    [10], [0.600], [$1/15$],  [0.155], [0.296], [0.904],
    [18], [0.500], [$1/10$],  [0.158], [0.190], [0.810],
    [25], [0.400], [$3/20$],  [0.155], [0.096], [0.704],
  ),
  caption: [Greenwood 95% confidence band. Upper bounds at days 3 and 5 are capped at 1.],
)

At day 25 the estimate is 40%, but with 95% confidence the true value lies between 10% and 70%. At day 18, where the median is, the band runs from 19% to 81%. With ten servers the curve is informative, but we cannot trust its exact numbers. The more servers we observe, the narrower the band becomes. The interval is only approximate, because the number of servers is small.

#figure(
  canvas({
    plot.plot(
      size: (10, 6),
      x-label: [Day],
      y-label: [$hat(S)(t)$],
      x-min: 0, x-max: 31,
      y-min: 0, y-max: 1.05,
      x-tick-step: 5,
      y-tick-step: 0.2,
      {
        let lower = (
          (0, 1), (3, 1), (3, 0.714), (5, 0.714), (5, 0.552), (10, 0.552),
          (10, 0.296), (18, 0.296), (18, 0.190), (25, 0.190), (25, 0.096), (30, 0.096),
        )
        let upper = (
          (0, 1), (3, 1), (3, 1), (5, 1), (5, 1), (10, 1),
          (10, 0.904), (18, 0.904), (18, 0.810), (25, 0.810), (25, 0.704), (30, 0.704),
        )
        plot.add-fill-between(lower, upper,
          style: (stroke: none, fill: rgb("#1f77b4").transparentize(80%)))
        plot.add((
          (0, 1), (3, 1), (3, 0.9), (5, 0.9), (5, 0.8),
          (10, 0.8), (10, 0.6), (18, 0.6), (18, 0.5),
          (25, 0.5), (25, 0.4), (30, 0.4),
        ), style: (stroke: rgb("#1f77b4")))
        plot.add(((30, 0.4),), mark: "x", style: (stroke: none), mark-style: (stroke: red))
      },
    )
  }),
  caption: [Kaplan–Meier curve with a 95% Greenwood confidence band. The band widens as fewer servers remain at risk.],
)

= Conclusion

+ Both averages were too low (12 and 19 days) because the data are censored.
+ The Kaplan–Meier method uses all servers, including those that are still reachable, and gives an honest estimate: the median is about 18 days.
+ Greenwood's formula shows the cost of this answer: with ten servers the confidence band is very wide, so we need either more data or cautious conclusions.

= Limitations

+ The data are synthetic, and there are only ten servers.
+ The interval is approximate: the normal approximation is crude for small samples.
+ The method assumes that servers are independent and that censoring is unrelated to the risk of blocking. In reality, blocks come in waves, so this is a simplification.
+ The method shows how long servers survive, not why they were blocked.

= References

+ Kaplan, E. L., & Meier, P. (1958). Nonparametric estimation from incomplete observations. _Journal of the American Statistical Association_, 53(282), 457–481.
