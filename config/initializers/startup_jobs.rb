Rails.application.config.after_initialize do
  FillMissingTranslatesJob.perform_later
end
