class OutsReport < Report
  @title = 'Outs Report'

  def to_table
    table = Table(%w(Status All Blastouts Mashouts Shoutouts))

    if self.date_range
      outs      = Out.where(:created_at => self.date_range)
    else
      outs = Out.all
    end

    blastouts = outs.where(:type => Blastout)
    mashouts  = outs.where(:type => Mashout)
    shoutouts = outs.where(:type => Shoutout)

    successful_outs      = outs.select { |out| out.successful? }
    successful_blastouts = blastouts.select { |out| out.successful? }
    successful_mashouts  = mashouts.select { |out| out.successful? }
    successful_shoutouts = shoutouts.select { |out| out.successful? }

    table << build_out_count_row('Successful',
                                 successful_outs,
                                 successful_blastouts,
                                 successful_mashouts,
                                 successful_shoutouts)

    unsuccessful_outs      = outs - successful_outs
    unsuccessful_blastouts = blastouts - successful_blastouts
    unsuccessful_mashouts  = mashouts - successful_mashouts
    unsuccessful_shoutouts = shoutouts - successful_shoutouts

    table << build_out_count_row('Unsuccessful',
                                 unsuccessful_outs,
                                 unsuccessful_blastouts,
                                 unsuccessful_mashouts,
                                 unsuccessful_shoutouts)

    table << { 'Status'    => 'Total',
               'All'       => table.sum('All'),
               'Blastouts' => table.sum('Blastouts'),
               'Mashouts'  => table.sum('Mashouts'),
               'Shoutouts' => table.sum('Shoutouts') }

     table
  end

  protected
    def build_out_count_row(status, all, blastouts, mashouts, shoutouts)
      { 'Status'    => status,
        'All'       => all.count,
        'Blastouts' => blastouts.count,
        'Mashouts'  => mashouts.count,
        'Shoutouts' => shoutouts.count }
    end
end