# TraceX - PCB Surface Defect Detection 

AI - VISION powered smart inspection system for high speed consumer electronics PCB assembly
Model fine-tuned as part of **DesignIQ** (OpenHack 24-hour hackathon project) — an AI-powered PCB and CAD design quality checker combining YOLOv8/YOLOv11 visual defect detection, LLM-based KiCad netlist analysis, and BOM CSV validation.

## Dataset

- **Source:** [DsPCBSD+](https://www.kaggle.com/datasets/enisteper1/dataset-of-pcb-surface-defects-dspcbsd) — Dataset of PCB Surface Defects
- **Total images:** 10,259 | **Total annotated defects:** 20,276
- **Validation set:** 2,051 images, 4,092 instances
- **Classes (9):** `short`, `spur`, `spurious_copper`, `open`, `mouse_bite`, `hole_breakout`, `conductor_scratch`, `conductor_foreign_object`, `base_material_foreign_object`
- **Format:** YOLO (bounding box annotations)
- Citation: Lv, S., Ouyang, B., Deng, Z. et al. *A dataset for deep learning based detection of printed circuit board surface defect.* Scientific Data 11, 811 (2024). https://doi.org/10.1038/s41597-024-03656-8

## Training Configuration

| Parameter | Value |
|---|---|
| Base model | YOLOv11n (`yolo11n.pt`) |
| Epochs | 25 |
| Image size | 640 |
| Batch size | 16 |
| Optimizer | AdamW |
| LR0 | 1e-3 |
| Scheduler | Cosine LR (`cos_lr=True`) |
| Close mosaic | 10 |
| Patience | 20 |
| Hardware | Tesla T4 (Colab) |

## Overall Validation Results

| Metric | Score |
|---|---|
| **Precision** | 0.801 |
| **Recall** | 0.766 |
| **mAP50** | 0.830 |
| **mAP50-95** | 0.484 |

## Per-Class Results

| Class | Images | Instances | Precision | Recall | mAP50 | mAP50-95 |
|---|---|---|---|---|---|---|
| hole_breakout | 271 | 608 | 0.908 | 0.947 | **0.983** | 0.821 |
| short | 126 | 169 | 0.784 | 0.852 | 0.883 | 0.550 |
| base_material_foreign_object | 305 | 346 | 0.836 | 0.858 | 0.889 | 0.443 |
| open | 274 | 338 | 0.791 | 0.849 | 0.864 | 0.502 |
| spur | 430 | 929 | 0.833 | 0.723 | 0.824 | 0.372 |
| spurious_copper | 245 | 285 | 0.780 | 0.716 | 0.800 | 0.484 |
| mouse_bite | 391 | 546 | 0.823 | 0.698 | 0.799 | 0.379 |
| conductor_scratch | 279 | 448 | 0.735 | 0.643 | 0.719 | 0.428 |
| conductor_foreign_object | 309 | 423 | 0.719 | 0.605 | 0.710 | 0.379 |

## Observations

- Strongest class: **hole_breakout** (mAP50 = 0.983) — visually distinct and consistently detected.
- Weakest classes: **conductor_scratch** and **conductor_foreign_object** (mAP50 ≈ 0.71–0.72) — likely confused with each other and with `base_material_foreign_object` due to visual similarity (scratch-like / foreign-object patterns).
- Strong result at only 25 epochs on a 9-class dataset — indicates headroom for further improvement with extended training (60–80+ epochs), given `patience=20` allows early stopping if validation plateaus.

## Next Steps

- Extend training beyond 25 epochs to improve weaker classes.
- Export to ONNX/TensorRT if deploying outside a Python/Ultralytics stack.
- Integrate as the visual defect detection component of DesignIQ, alongside LLM-based KiCad netlist analysis and BOM CSV validation with EOL flagging.
