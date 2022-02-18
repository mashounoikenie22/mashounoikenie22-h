class ProvidersReport < Report
  @title = 'Providers Report'

  def to_table
    table                        = Table(['Provider', 'Accounts Created', 'Blastouts', 'Mashouts', 'Shoutouts'])
    providers                    = [Authorization::FACEBOOK,
                                    Authorization::TWITTER,
                                    [Authorization::FACEBOOK,
                                     Authorization::TWITTER]]
    users_with_one_authorization = User.joins(:authorizations)
                                       .select('"users"."id"')
                                       .group('"users"."id"')
                                       .having('count(*) = 1')
                                       .map(&:id)

    providers.each do |provider|
      if provider.is_a?(String)
        # Users that authorized this provider
        authorizations      = Authorization.joins(:user).where(:provider => provider,
                                                               :users => { :id => users_with_one_authorization })
        authorized_user_ids = authorizations.map(&:user_id)
        provider_name       = "#{provider.titleize} Only"
        report_row          = build_provider_report_row(provider_name,
                                                        authorized_user_ids)

        if self.date_range
          authorizations_by_date = authorizations.where(:created_at => self.date_range)

          report_row.merge!('Accounts Created' => authorizations_by_date.count)
        else
          report_row.merge!('Accounts Created' => authorized_user_ids.count)
        end

        table << report_row
      else
        user_ids = []

        # Get the users for each provider
        provider.each do |individual_provider|
          authorizations = Authorization.where(:provider => individual_provider)
          user_ids << authorizations.map(&:user_id)
        end

        # Intersect the users from each provider to get the users that
        # have authorized with all providers in the list
        user_ids      = user_ids.inject(:&)
        provider_name = provider.map(&:titleize).join(' + ')
        report_row    = build_provider_report_row(provider_name, user_ids)

        if self.date_range
          user_ids_by_date = []

          provider.each do |individual_provider|
            authorizations = Authorization.where(:provider => individual_provider, :created_at => self.date_range)
            user_ids_by_date << authorizations.map(&:user_id)
          end

          user_ids_by_date = user_ids_by_date.inject(:&)

          report_row.merge!('Accounts Created' => user_ids_by_date.count)
        else
          report_row.merge!('Accounts Created' => user_ids.count)
        end

        table << report_row
      end
    end

    table << { 'Provider'         => 'Total',
               'Accounts Created' => table.sum('Accounts Created'),
               'Blastouts'        => table.sum('Blastouts'),
               'Mashouts'         => table.sum('Mashouts'),
               'Shoutouts'        => table.sum('Shoutouts') }

    table
  end

  protected
    def build_provider_report_row(provider, user_ids)
      blastout_count, mashout_count, shoutout_count = out_count(user_ids)
      { 'Provider'    => provider,
        'Blastouts'   => blastout_count,
        'Mashouts'    => mashout_count,
        'Shoutouts'   => shoutout_count }
    end

    def out_count(user_ids)
      return [0, 0, 0] if user_ids.empty?

      blastouts = Blastout.where(:user_id => user_ids)
      mashouts  = Mashout.where(:user_id => user_ids)
      shoutouts = Shoutout.where(:user_id => user_ids)

      if self.date_range
        blastouts = blastouts.where(:created_at => self.date_range)
        mashouts  = mashouts.where(:created_at => self.date_range)
        shoutouts = shoutouts.where(:created_at => self.date_range)
      end

      blastouts = blastouts - blastouts.joins(:out_errors)
      mashouts  = mashouts  - mashouts.joins(:out_errors)
      shoutouts = shoutouts - shoutouts.joins(:out_errors)

      [blastouts.count, mashouts.count, shoutouts.count]
    end
end