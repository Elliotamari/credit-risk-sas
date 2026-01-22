# Credit Risk Modeling - Loan Default Prediction


## Overview

This project develops a **credit risk scoring model** using historical loan data from LendingClub, focusing on predicting loan defaults. The objective is to create a **probability of default (PD)** scorecard, using a combination of **logistic regression** and a **decision tree (HPSPLIT)** to assess the likelihood of loan repayment or default.

### Key Features:

* **Data Exploration and Cleaning**: Preprocessing and cleaning the dataset to handle missing values, remove rare categories, and create meaningful features.
* **Feature Engineering**: Deriving new features such as the log-transformed income, capped DTI values, and handling categorical features using standard transformations.
* **Modeling**: Developing two types of models:

  * **Logistic Regression (Baseline PD Model)**: Used to predict the probability of default using linear relationships.
  * **Decision Tree (HPSPLIT)**: A decision tree model is trained using the `HPSPLIT` procedure, providing a non-linear alternative to logistic regression.
* **Evaluation**: Evaluating model performance using AUC (ROC), KS statistic, confusion matrix at a chosen cutoff, and decile tables with lift and cumulative bad capture.

---

## Files and Directories

### 1. **Data Processing**

* `02_clean_target.sas`: Cleans the `loan_status` column and generates the target variable `default` for classification (0 = Fully Paid, 1 = Charged Off).
* `03b_collapse_rare_levels.sas`: Collapses rare categories in categorical variables into "OTHER" for model stability.

### 2. **Modeling**

* `05_logistic_baseline.sas`: Trains a **baseline Logistic Regression** model on the training data, produces a probability of default (PD), and evaluates the model using AUC, KS statistic, confusion matrix, and decile table.
* `06a_model_tree_hpsplit.sas`: Trains a **Decision Tree (HPSPLIT)** model, generating scoring code, scoring the test set, and evaluating the model with AUC, KS, confusion matrix, and decile table.

### 3. **Evaluation**

* **Performance Metrics**:

  * **AUC (ROC)**: Measures the ability of the model to differentiate between good and bad loans.
  * **KS Statistic**: Measures the maximum difference between the cumulative distribution of defaults and non-defaults.
  * **Confusion Matrix**: Evaluates the model performance at different cutoffs.
  * **Decile Table & Lift**: Analyzes model performance in deciles and calculates lift (the improvement over random guessing).

---

## Setup

### Requirements

1. **SAS**: This project is built using SAS for data processing, modeling, and evaluation.
2. **LendingClub Data**: The project uses a dataset from LendingClub (CSV format). You can import the data using `proc import` in SAS.

### Installation

1. Clone this repository to your local machine or open it in SAS Studio.
2. Set the correct file paths for your input data.

```sas
%let project = /path/to/your/data;
%let file = accepted_2007_to_2018Q4.csv;
```

3. Run the **SAS scripts** in the following order to clean the data, train the models, and evaluate performance:

   1. `02_clean_target.sas`
   2. `03b_collapse_rare_levels.sas`
   3. `05_logistic_baseline.sas`
   4. `06_model_tree_hpsplit.sas`

---

## Model Results

### Logistic Regression (Baseline Model)

* **AUC**: 0.736 (Train)
* **KS Statistic**: 0.3439 (Test)
* **Confusion Matrix at Cutoff=0.20**:

  * **True Positives (default = 1)**: 15,516
  * **True Negatives (default = 0)**: 59,501
  * **False Positives**: 3,046
  * **False Negatives**: 7,233

### Decision Tree (HPSPLIT)

* **AUC**: 0.716 (Train)
* **KS Statistic**: 0.3224 (Test)
* **Confusion Matrix at Cutoff=0.20**:

  * **True Positives (default = 1)**: 14,221
  * **True Negatives (default = 0)**: 62,776
  * **False Positives**: 27,218
  * **False Negatives**: 8,538

### Decile Table (Lift and Cumulative Bad Capture)

For both models, we calculate the lift and cumulative bad capture by dividing the population into deciles based on the predicted probability of default (PD).

* **Lift**: The ratio of bad rate in the decile vs. overall bad rate. Higher lift indicates better model performance in predicting defaults.
* **Cumulative Bad Capture**: The cumulative percentage of defaults captured by each decile.

---

## Conclusion

This credit risk modeling project provides an end-to-end workflow for developing, evaluating, and deploying predictive models for loan default. The combination of **logistic regression** and **decision tree (HPSPLIT)** offers different perspectives on the data, and the evaluation using **AUC**, **KS statistic**, **confusion matrix**, and **deciles with lift** ensures that the model is both bank-friendly and highly interpretable.

---

## Next Steps

* **Model Tuning**: Hyperparameter tuning for both models to improve performance.
* **Model Deployment**: Integration into a banking environment for real-time credit risk assessment.
* **Advanced Techniques**: Experiment with other machine learning models like Random Forest or Gradient Boosting for improved performance.

---

## License

This project does not include any specific license. You may use or modify the code as per your needs.

---

### Additional Sections:

#### **Version Control**:

The project is tracked and version-controlled using **GitHub**. Git was used to manage updates, track changes, and collaborate with other developers. The project repository can be found on [GitHub](https://github.com/yourusername/credit-risk-sas).

#### **Tools**:

* **GitHub**: Version control and collaborative development.
* **SAS**: Data processing, cleaning, and model building.
* **Visual Studio**: Integrated development environment for running and managing SAS scripts.
