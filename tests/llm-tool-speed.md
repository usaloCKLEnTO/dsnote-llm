# 🧠 LLM Speech-to-Text Cleanup Benchmark Summary

## ✅ Top Performing Models

| Model                | Avg Latency (ms) | Cleanup Accuracy | Notes                                      |
|---------------------|------------------|------------------|--------------------------------------------|
| **groq-llama3-70b**  | 587              | 100%             | Fastest overall, clean and accurate output |
| **groq-llama-3.3-70b**| 587              | 100%             | Identical performance to llama3-70b        |
| **gpt-4-turbo**      | 1218             | 100%             | Accurate, moderate latency                 |
| **gpt-4o**           | 1270             | 100%             | Consistent, slightly slower than turbo     |

## ⚠️ Acceptable Alternatives

| Model                    | Avg Latency (ms) | Cleanup Accuracy | Notes                                           |
|-------------------------|------------------|------------------|-------------------------------------------------|
| gemini-2.5-flash-lite    | 885              | 95%              | Occasional paraphrasing, generally clean        |
| groq-kimi-k2             | 671              | 95%              | Fast, minor formatting issues in one run        |
| claude-3.5-sonnet        | 2189             | 95%              | Accurate but significantly slower               |
| gpt-3.5-turbo            | 1123             | 90%              | Slight verbosity retained in some cases         |

## 🚫 Not Recommended for Interactive Use

| Model                                | Avg Latency (ms) | Cleanup Accuracy | Notes                                                   |
|-------------------------------------|------------------|------------------|----------------------------------------------------------|
| mistral-7b-instruct:free            | 1661             | 70%              | Meta formatting and example wrappers in outputs          |
| gpt-4o-mini                         | 1149             | 60%              | Prompt returned instead of cleaned text in 2/5 samples   |
| gemini-2.5-flash                    | 3002             | 70%              | Missed grammar corrections, slow                         |
| gemini-2.5-pro                      | 10123            | 100%             | Very accurate but unusably slow (~10s per response)      |

---

## 🏁 Recommendation

- **Best overall**: `groq-llama3-70b` or `groq-llama-3.3-70b` — high cleanup fidelity with sub-second latency.
- **Good fallback**: `gpt-4o` or `gpt-4-turbo` — slightly higher latency, still excellent accuracy.
- **Free option to try cautiously**: `mistral-7b-instruct:free` — useful with system prompts or regex post-cleanup to remove boilerplate.
