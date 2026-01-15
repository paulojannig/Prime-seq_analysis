# attributes <- listAttributes(useMart("ensembl", dataset = "mmusculus_gene_ensembl"))
if (species == "human") {
  dataset <- "hsapiens_gene_ensembl"
  symbol <- "hgnc_symbol"
  organism <- "org.Hs.eg.db"
  db_species <- "HS" # to be implemented into msigdbr
} else if (species == "mouse") {
  dataset <- "mmusculus_gene_ensembl"
  symbol <- "mgi_symbol"
  organism <- "org.Mm.eg.db"
  db_species <- "MM" # to be implemented into msigdbr
} else if (species == "pig") {
  dataset <- "sscrofa_gene_ensembl"
  symbol <- "hgnc_symbol"
} else {
  stop("Error at defining species")
}

# DESeqDataSetFromFeatureCounts ==========================================
# Check https://www.biostars.org/p/277316/#277350
DESeqDataSetFromFeatureCounts <- function(sampleTable,
                                          directory = ".",
                                          design,
                                          ignoreRank = FALSE, ...) {
  names(sampleTable)[1:2] <- c("sample", "file")
  if (missing(design)) {
    stop("design is missing")
  }
  l <- lapply(as.character(sampleTable$file), function(fn) {
    read.table(file.path(directory, fn), skip = 2)
  }
  )
  if (!all(sapply(l, function(a) { 
    all(a$V1 == l[[1]]$V1)
  }))) 
  {
    stop("Gene IDs (first column) differ between files.")
  }
  tbl <- sapply(l, function(a) a$V7)
  colnames(tbl) <- sampleTable$sample
  rownames(tbl) <- l[[1]]$V1
  rownames(sampleTable) <- sampleTable$sample
  dds <- DESeqDataSetFromMatrix(countData = tbl, colData = sampleTable[,
                                                                       -(2),
                                                                       drop = FALSE
  ], design = design, ignoreRank, ...)
  return(dds)
}


# PCA plot DESeq2 function ==========================================
plot_pca_deseq <- function(dds,
                           group = "group",
                           plot_center = TRUE,
                           linetype = "solid",
                           palette = NULL) {
  vsd <- DESeq2::vst(dds, blind = FALSE)
  
  pca_data <- DESeq2::plotPCA(vsd, intgroup = c(group), returnData = TRUE)
  percent_var <- round(100 * attr(pca_data, "percentVar"))
  segments <- pca_data %>%
    dplyr::group_by(!!as.symbol("group")) %>%
    dplyr::summarise(xend = mean(PC1), yend = mean(PC2))
  pca_data <- merge(pca_data, segments, by = "group")
  
  no_colors <- pca_data[, "group"] %>%
    unique() %>%
    length()
  
  if (plot_center == TRUE) {
    p <- pca_data %>%
      ggplot2::ggplot(ggplot2::aes(PC1, PC2, fill = !!as.symbol("group"))) +
      ggplot2::geom_segment(
        ggplot2::aes(x = PC1, y = PC2, xend = xend, yend = yend),
        linewidth = 0.3,
        linetype = linetype
      ) +
      ggplot2::geom_point(
        data = segments,
        ggplot2::aes(x = xend, y = yend),
        size = 0.5
      )
  } else {
    p <- pca_data %>%
      ggplot2::ggplot(ggplot2::aes(PC1, PC2, fill = !!as.symbol("group")))
  }
  
  # ggplot2::geom_point(size = 2)
  p <- p + ggplot2::geom_point(size = 2, shape = 21, color = "black") +
    ggplot2::xlab(paste0("PC1: ", percent_var[1], "% variance")) +
    ggplot2::ylab(paste0("PC2: ", percent_var[2], "% variance")) +
    gg_theme() +
    ggplot2::theme(legend.position = "top")
  
  if (is.null(palette)) {
    p <- p +
      ggplot2::scale_color_manual(values = viridis::viridis(no_colors + 1)) +
      ggplot2::scale_fill_manual(values = viridis::viridis(no_colors + 1))
  } else {
    p <- p +
      ggplot2::scale_color_manual(
        values = palette,
        aesthetics = c("color", "fill")
      )
  }
  return(p)
}

# ggplot theme ==========================================
gg_theme <- function() {
  theme_bw() +
    theme(
      text = element_text(family = "Helvetica", color = "black", size = 6 / ggplot2:::.pt),
      rect = element_rect(fill = "transparent"),
      plot.title = ggtext::element_markdown(size = 6, hjust = 0.5),
      
      # panel options
      panel.background = element_rect(fill = "transparent"),
      panel.border = element_rect(
        linetype = "solid",
        color = "black",
        linewidth = 0.5,
        fill = NA
      ),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.25),
      panel.grid.minor = element_blank(),
      panel.spacing.y = unit(1, "lines"),
      
      # axis options
      axis.title = ggtext::element_markdown(size = 5, vjust = 0.5),
      axis.title.x = ggtext::element_markdown(size = 5, vjust = 0.5),
      axis.title.y = ggtext::element_markdown(size = 5, vjust = 0.5),
      axis.text = ggtext::element_markdown(size = 5, colour = "black"),
      axis.text.x = ggtext::element_markdown(size = 5, colour = "black"),
      axis.ticks = element_line(linewidth = 0.25, color = "black"),
      axis.ticks.length = unit(0.5, "mm"),
      
      # legend options
      legend.background = element_rect(fill = "transparent"),
      legend.key.size = unit(3, "mm"),
      legend.title = ggtext::element_markdown(size = 6),
      legend.text = element_text(size = 5, colour = "black"),
      legend.box.spacing = unit(-1, "mm"),
      legend.position = "none",
      
      # other
      strip.background = element_blank(),
      strip.text = element_text(size = 5, 
                                colour = "black", 
                                vjust = 0, 
                                face = "italic")
    )
}

# ggsave function ==========================================
ggsave_fixed = function(file, plot = ggplot2::last_plot(), 
                        units = "mm",
                        margin = 1, 
                        plot_width = 4,
                        plot_height = 4, 
                        width = round(dev.size()[1], digits = 1), 
                        height = round(dev.size()[1], digits = 1)) {
  pf = egg::set_panel_size(p = plot,
                           file = NULL, 
                           margin = unit(margin, units),
                           width = unit(plot_width, units), 
                           height = unit(plot_height, units))
  ggsave(file, plot = pf, units = units, width = width, height = height, dpi = 300)
}