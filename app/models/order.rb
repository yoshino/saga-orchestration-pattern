class Order < ApplicationRecord
  enum status: { ready: 0, approved: 1, rejected: 2 }
end