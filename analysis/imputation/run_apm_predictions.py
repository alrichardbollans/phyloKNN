from sklearn.linear_model import LogisticRegression
from sklearn.metrics import average_precision_score, make_scorer
from tqdm import tqdm
from xgboost import XGBClassifier

from analysis.data.apm_data_sample import number_of_apm_folds
from analysis.imputation.helper_functions import get_prediction_data_paths, phylnn_predict
from analysis.imputation.run_encodings_predictions import get_umap_data, add_y_to_data, get_eigenvectors, get_autoencoded_data, logit_init_kwargs, \
    logit_grid_search_params, fit_and_output, xgb_clf_init_kwargs, xgb_clf_grid_search_params
from phylokNN import nan_safe_metric_wrapper


def run_predictions():
    for iteration in tqdm(range(1, number_of_apm_folds + 1)):
        m= 'mcar'
        bin_or_cont = 'binary'

        real_or_sim = 'my_apm_data'
        average_precision_score_nan_safe = nan_safe_metric_wrapper(average_precision_score)
        _scorer = make_scorer(average_precision_score_nan_safe, greater_is_better=True, response_method='predict_proba')
        phylnn_predict(real_or_sim, 'binary', iteration, m, _scorer)

        umap_X = get_umap_data(real_or_sim, bin_or_cont, iteration)
        umap_df, umap_encoding_vars, umap_target_name = add_y_to_data(umap_X, real_or_sim, bin_or_cont, iteration, m)

        eigen_X = get_eigenvectors(real_or_sim, bin_or_cont, iteration)
        eigen_df, eigen_encoding_vars, eigen_target_name = add_y_to_data(eigen_X, real_or_sim, bin_or_cont, iteration, m)

        autoenc_X = get_autoencoded_data(real_or_sim, bin_or_cont, iteration)
        autoenc_df, autoenc_encoding_vars, autoenc_target_name = add_y_to_data(autoenc_X, real_or_sim, bin_or_cont, iteration, m)
        out_dir = get_prediction_data_paths(real_or_sim, bin_or_cont, iteration, m)

        if bin_or_cont == 'binary':
            clf_instance = LogisticRegression(**logit_init_kwargs)
            fit_and_output(clf_instance, logit_grid_search_params, out_dir, 'logit_umap', umap_df, umap_encoding_vars, umap_target_name,
                           bin_or_cont, scorer='average_precision')

            clf_instance = LogisticRegression(**logit_init_kwargs)
            fit_and_output(clf_instance, logit_grid_search_params, out_dir, 'logit_eigenvecs', eigen_df, eigen_encoding_vars,
                           eigen_target_name, bin_or_cont, scorer='average_precision')

            clf_instance = XGBClassifier(**xgb_clf_init_kwargs)
            fit_and_output(clf_instance, xgb_clf_grid_search_params, out_dir, 'xgb_umap', umap_df, umap_encoding_vars, umap_target_name,
                           bin_or_cont, scorer='average_precision')

            clf_instance = XGBClassifier(**xgb_clf_init_kwargs)
            fit_and_output(clf_instance, xgb_clf_grid_search_params, out_dir, 'xgb_eigenvecs', eigen_df, eigen_encoding_vars,
                           eigen_target_name, bin_or_cont, scorer='average_precision')
            # ### autoencoder
            clf_instance = LogisticRegression(**logit_init_kwargs)
            fit_and_output(clf_instance, logit_grid_search_params, out_dir, 'logit_autoencoded', autoenc_df, autoenc_encoding_vars,
                           eigen_target_name, bin_or_cont, scorer='average_precision')

            clf_instance = XGBClassifier(**xgb_clf_init_kwargs)
            fit_and_output(clf_instance, xgb_clf_grid_search_params, out_dir, 'xgb_autoencoded', autoenc_df, autoenc_encoding_vars,
                           umap_target_name,
                           bin_or_cont, scorer='average_precision')
            # # ### Semisupervised cases not included. The general simulation analysis shows they dont provide improvement


if __name__ == '__main__':
    run_predictions()
