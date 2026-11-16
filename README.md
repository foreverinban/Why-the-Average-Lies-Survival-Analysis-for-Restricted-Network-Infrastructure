# Why the Average Lies

**Survival Analysis for Restricted Network Infrastructure**

A short, hands-on article on why the average lifetime misleads when some servers are still reachable at the end of observation (censored data). It walks through a synthetic ten-server example, the Kaplan–Meier estimator, and a Greenwood confidence band.

- `paper.typ`: article source ([Typst](https://typst.app))
- `Why-the-Average-Lies-...-Palii-I.pdf`: compiled article

The data in the article are synthetic.

## Build

```
typst compile paper.typ
```

The figures use the CeTZ and cetz-plot packages, which Typst downloads automatically on the first run.

## Author

Ivan Palii, Dublin City University.

Language edited with AI assistance.

## License

CC BY 4.0, see `LICENSE`.
