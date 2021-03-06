# frozen_string_literal: true

#
# Document
#
class Document < ApplicationRecord
  mount_uploader :upload, UploadUploader

  #TYPES = ['Passport', 'Identity card', 'Driver license', 'Utility Bill'].freeze
  TYPES = ['Passport', 'National ID card', 'Country ID card', 'Driver license', 'PAN card', 'Birth certificate', 'Voter ID', 'Citizenship passport', 'Utility Bill', 'Others'].freeze
  STATES = %w[verified pending rejected].freeze

  scope :kept, -> { joins(:account).where(accounts: { discarded_at: nil }) }

  belongs_to :account
  serialize :metadata, JSON
  validates :doc_type, :upload, presence: true
  validates :doc_number, :doc_expire, presence: {message: "can't be blank unless Utility Bill"}, if: proc { |a| a.doc_type != 'Utility Bill'}
  validates :doc_type, inclusion: { in: TYPES }

  validates :doc_number, length: { maximum: 128 },
                         format: {
                           with: /\A[A-Za-z0-9\-\s]+\z/,
                           message: 'only allows letters and digits'
                         }, if: proc { |a| a.doc_number.present? }
  validates_format_of :doc_expire,
                      with: /\A\d{4}\-\d{2}\-\d{2}\z/,
                      message: 'Date must be in the following format: yyyy-mm-dd',
                      if: proc { |a| a.doc_type != 'Utility Bill'}
  validate :doc_expire_not_in_the_past
  after_commit :create_or_update_document_label, on: :create

private

  def doc_expire_not_in_the_past
    return if doc_expire.blank?
    errors.add(:doc_expire, :invalid) if doc_expire < Date.current
  end

  def create_or_update_document_label
    account_document_label = account.labels.find_by(key: :document)
    if account_document_label.nil?
      account.labels.create(key: :document, value: :pending, scope: :private)
    elsif account_document_label.value != 'verified'
      account_document_label.update(value: :pending)
    end
  end
end

# == Schema Information
# Schema version: 20190626065821
#
# Table name: documents
#
#  id         :bigint(8)        not null, primary key
#  account_id :bigint(8)
#  upload     :string(255)
#  doc_type   :string(255)
#  doc_number :string(255)
#  doc_expire :date
#  metadata   :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_documents_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_dd871098c0  (account_id => accounts.id)
#
