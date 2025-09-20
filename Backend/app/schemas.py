from pydantic import BaseModel
from typing import List, Optional
from decimal import Decimal
from datetime import datetime
from pydantic import BaseModel

class UserPublic(BaseModel):
    name: str
    email: str
    phone: str
    address: str

    class Config:
        orm_mode = True

# ---------- User ----------
class UserBase(BaseModel):
    name: str
    email: str
    phone: Optional[str] = None
    address: Optional[str] = None
    role: str

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    class Config:
        from_attributes = True

# ---------- Product ----------
class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: Decimal
    image_url: Optional[str] = None
    available: bool = True

class ProductResponse(ProductBase):
    id: int
    class Config:
        from_attributes = True

# ---------- Cart ----------
class CartItem(BaseModel):
    id: int
    product: ProductResponse
    quantity: int
    class Config:
        from_attributes = True

# ---------- Orders ----------
class OrderItemBase(BaseModel):
    product_id: int
    quantity: int
    price: Decimal

class OrderItemResponse(OrderItemBase):
    id: int
    class Config:
        from_attributes = True

# class OrderResponse(BaseModel):
#     id: int
#     user_id: int
#     status: str
#     total_price: Decimal
#     items: List[OrderItemResponse]
#     created_at: datetime
#     class Config:
#         from_attributes = True
class OrderResponse(BaseModel):
    id: int
    user_name: str  # new field instead of user_id
    status: str
    total_price: Decimal
    items: List[OrderItemResponse]
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None

    class Config:
        from_attributes = True