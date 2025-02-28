import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from kmodes.kmodes import KModes

# Load the data
financial_data = pd.read_csv("Financial_Literacy.csv")
likert_data = pd.read_csv("Likert_OSC.csv")
all_data = pd.read_csv("All_Raw_Data_OSC.csv")

# Clean and preprocess the data
financial_data.dropna(subset=['participant_code'], inplace=True)
likert_data.dropna(subset=['participant_code'], inplace=True)
likert_data.drop("attention_check_question", axis=1, inplace=True)

# Merge datasets
clean_financial = financial_data.merge(all_data, on="participant_code", how="inner").iloc[:, [0, -5, -4, -3]]
all_data = pd.merge(clean_financial, likert_data, on='participant_code')

# Rename columns for clarity
all_data.columns = ['ID', 'fin1', "fin2", "fin3", "lik1", "lik2", "lik3", "lik4", "lik5", "lik6", "lik7", "lik8", "lik9"]

# Recode financial literacy questions
fin1_mapping = {"More than $102": "Right", "I don't know": "Wrong", 'It is impossible to tell': 'Wrong', 'Less than $102': 'Wrong', 'Exactly 102': 'Wrong'}
all_data['FL1'] = all_data['fin1'].map(fin1_mapping)

fin2_mapping = {'Less than today': "Right", "I don't know": "Wrong", 'More than today': 'Wrong', 'Exactly the same as today': 'Wrong'}
all_data['FL2'] = all_data['fin2'].map(fin2_mapping)

fin3_mapping = {'FALSE': "Right", "I don't know": "Wrong", 'TRUE': 'Wrong'}
all_data['FL3'] = all_data['fin3'].map(fin3_mapping)

# Convert Likert scale responses to categorical values
likert_cols = ["lik1", "lik2", "lik3", "lik4", "lik5", "lik6", "lik7", "lik8", "lik9"]
likert_mapping = {-3: 'Strongly Disagree', -2: 'Disagree', -1: 'Slightly Disagree', 0: 'Neither Agree Nor Disagree', 1: 'Slightly Agree', 2: 'Agree', 3: 'Strongly Agree'}
all_data[likert_cols] = all_data[likert_cols].replace(likert_mapping)

# Convert data to matrix form for clustering
data_matrix = all_data.iloc[:, 4:].to_numpy()

# Determine the optimal number of clusters using the Elbow method
cost = []
for num_clusters in range(1, 10):
    kmode = KModes(n_clusters=num_clusters, init="Huang", n_init=10)
    kmode.fit_predict(data_matrix)
    cost.append(kmode.cost_)

plt.plot(range(1, 10), cost)
plt.xlabel('Number of Clusters')
plt.ylabel('Cost')
plt.title('Elbow Method for Optimal K')
plt.savefig('elbow_method.png')
plt.show()

# Apply KModes clustering
kmodes = KModes(n_jobs=-1, n_clusters=2, init='Huang', random_state=0)
clusters = kmodes.fit_predict(data_matrix)

# Add cluster labels to the original dataset
all_data['Cluster_Labels'] = clusters
all_data['Segment'] = all_data['Cluster_Labels'].map({0: 'First', 1: 'Second'})

# Save the clustered data
all_data.to_csv('clustering_output.csv', index=False)

#Visualize the results using radar chart
import plotly.graph_objects as go
categories = ['Funds with high ESG ratings always consist of companies that exhibit sustainable practices.',
              'I am influenced by ESG ratings when making investment decisions.',
              'I have faith in the fairness of the financial system.',
           'Financial returns are the most important outcome of my personal investment decisions.', 
              'I believe that finance and investing are effective ways to drive positive social change.',
              'Sustainability is the most important outcome of my personal investment decisions.',
          'Funds with high ESG ratings are generally less risky investments and provide higher returns over the medium or long term.',
              'I would accept reduced financial returns if it meant my investments would definitely contribute towards sustainable outcomes.',
              'I adhere to a monthly budget.']

fig = go.Figure()

fig.add_trace(go.Scatterpolar(
      r=[1,2,-1,2,2,2,1,1,2],
      theta=categories,
      fill='toself',
      name='Segment A'
))
fig.add_trace(go.Scatterpolar(
      r=[0,1,-2,2,1,1,0,-1,1],
      theta=categories,
      fill='toself',
      name='Segment B'
))

fig.update_layout(
  polar=dict(
    radialaxis=dict(
      visible=True,
      range=[-3,3]
    )),
  showlegend=True
)

fig.show()


