from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user

router = APIRouter()

def barista_only(user: models.User):
    if user.role != "barista":
        raise HTTPException(status_code=403, detail="Baristas only")

@router.get("/orders", response_model=list[schemas.OrderResponse])
def get_pending_orders(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    barista_only(current_user)
    return db.query(models.Order).filter(models.Order.status.in_(["pending", "in_progress"])).all()

@router.put("/orders/{order_id}/status")
def update_order_status(order_id: int, status: str, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    barista_only(current_user)
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    order.status = status
    db.commit()
    return {"message": f"Order {order_id} status updated to {status}"}


@router.get("/orders/completed", response_model=list[schemas.OrderResponse], tags=["Barista"])
def get_completed_orders(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    # Ensure only baristas can access
    barista_only(current_user)
    
    # Fetch all orders with status "completed"
    completed_orders = db.query(models.Order).filter(models.Order.status == "completed").all()
    return completed_orders
