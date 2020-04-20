PlotTSNEGG <- function(tsne_dist_projection, linelist_name, ref_type, output_dir, save_pdf) {

  # Plot the t-SNE projection of cases together with reference cases with ggplot. Returns the plot, if
  # save_pdf = TRUE then a PDF is exported.
  # ref_type is a tag appended to filenames, e.g. to distiguish between real and fake references.
  # WARNING: It assumes the t-SNE output has the reference cases at the beginning.

  tsne_dist_plot <- ggplot() +
    geom_point(data = tsne_dist_projection %>% filter(reference==linelist_name), aes(x = x, y = y),
      color = 'darkgrey') +
    geom_point(data = tsne_dist_projection %>% filter(reference!=linelist_name),
      aes(x = x, y = y, color = reference)) +
    ggtitle(linelist_name) +
    xlab('') +
    ylab('') +
    theme_bw() +
    theme(axis.text.x=element_blank(), axis.ticks.x=element_blank(),
      axis.text.y=element_blank(), axis.ticks.y=element_blank())

  if (save_pdf) {
    ggsave(plot=tsne_dist_plot, file=paste0(output_dir, '/tsne_dist_plots-', ref_type, '-',
      gsub(' ','_',linelist_name), '.pdf'), units='cm', width=13, height=10)
  }

  return(tsne_dist_plot)

}

