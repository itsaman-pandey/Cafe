from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user  
router = APIRouter(
    prefix="/orders",
    tags=["Orders"]
)

@router.post("/", response_model=schemas.OrderResponse)
def create_order(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):

    cart_items = db.query(models.Cart).filter(models.Cart.user_id == current_user.id).all()
    if not cart_items:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cart is empty")

    total_price = sum(item.product.price * item.quantity for item in cart_items)

    
    order = models.Order(user_id=current_user.id, total_price=total_price)
    db.add(order)
    db.commit()
    db.refresh(order)

    for item in cart_items:
        order_item = models.OrderItem(
            order_id=order.id,
            product_id=item.product_id,
            quantity=item.quantity,
            price=item.product.price
        )
        db.add(order_item)
    db.commit()
    db.refresh(order)

   
    db.query(models.Cart).filter(models.Cart.user_id == current_user.id).delete()
    db.commit()

    return order


# ----------------- Get Current User Orders -----------------
# @router.get("/", response_model=List[schemas.OrderResponse])
# def get_user_orders(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
#     orders = db.query(models.Order).filter(models.Order.user_id == current_user.id).all()
#     return orders

@router.get("/", response_model=List[schemas.OrderResponse])
def get_user_orders(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    orders = (
        db.query(models.Order)
        .filter(models.Order.user_id == current_user.id)
        .all()
    )

    # Map user_id to user_name
    result = []
    for order in orders:
        order_data = schemas.OrderResponse.from_orm(order)
        order_data.user_name = order.user.name  # populate name from relationship
        result.append(order_data)

    return result



# ----------------- Get All Orders (Admin) -----------------
# Uncomment if you have get_current_admin in dependencies
"""
from app.dependencies import get_current_admin

@router.get("/all", response_model=List[schemas.OrderResponse])
def get_all_orders(db: Session = Depends(get_db), admin: models.User = Depends(get_current_admin)):
    return db.query(models.Order).all()
"""
