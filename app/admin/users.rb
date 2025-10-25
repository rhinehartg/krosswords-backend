ActiveAdmin.register User do
  # Permit parameters for user management
  permit_params :email, :password, :password_confirmation

  # Index page configuration
  index do
    selectable_column
    id_column
    column :email
    column :created_at
    column :updated_at
    actions
  end

  # Show page configuration
  show do
    attributes_table do
      row :id
      row :email
      row :created_at
      row :updated_at
    end
  end

  # Form configuration
  form do |f|
    f.inputs "User Details" do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  # Filters
  filter :email
  filter :created_at
  filter :updated_at
end
