from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user

router = APIRouter()

def admin_only(user: models.User):
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admins only")

@router.post("/products", response_model=schemas.ProductResponse)
def add_product(product: schemas.ProductBase, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    admin_only(current_user)
    new_product = models.Product(**product.dict())
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return new_product

@router.get("/orders", response_model=list[schemas.OrderResponse])
def view_all_orders(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    admin_only(current_user)
    return db.query(models.Order).all()
