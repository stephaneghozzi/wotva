PlotScoresGG <- function(linelist, scores, ref_type, output_dir, save_pdf) {

  # Plot score distributions using ggplot for the cases in linelist, returns the plot, if save_pdf = TRUE,
  # then a PDF is exported.
  # ref_type is a tag appended to filenames, e.g. to distiguish between real and fake references.

  score_case_plot_df <- scores %>% group_by(reference) %>% mutate(mean_s1 = mean(s1))

  score_case_plot <- ggplot(score_case_plot_df, aes(x = reference)) +
    geom_quasirandom(aes(y = s1, fill = s1), color = 'black', shape = 21, varwidth = , alpha = 1) +
    geom_point(aes(y = mean_s1, fill = mean_s1), color = 'black', shape = 22, size = 3) +
    scale_x_discrete(limits = rev(scores %>% pull(reference) %>% unique())) +
    scale_fill_gradient2(low = 'orange', mid = 'beige', high = 'lightblue', limits = c(0, 1),
      midpoint = 0.5, space = 'Lab', na.value = 'grey50', guide = 'colourbar', aesthetics = 'fill') +
    ylim(c(0,1)) +
    ylab('score') +
    xlab('') +
    coord_flip() +
    ggtitle(nl) +
    theme_bw() +
    theme(legend.position = 'none')

  if (save_pdf) {
    ggsave(plot=score_case_plot, file=paste0(output_dir, '/score_plot-', ref_type,
      '-', gsub(' ','_',nl), '.pdf'), units = 'cm', width = 15, height = 10)
  }

  return(score_case_plot)

}
