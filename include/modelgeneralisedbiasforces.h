/*
 * <one line to give the program's name and a brief idea of what it does.>
 * Copyright (C) 2014  <copyright holder> <email>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 */

#ifndef MODELGENERALISEDBIASFORCES_H
#define MODELGENERALISEDBIASFORCES_H

#include "modelcomponent.h"
#include <boost/concept_check.hpp>

namespace mexWBIComponent
{
class ModelGeneralisedBiasForces : public ModelComponent
{
public:
   static ModelGeneralisedBiasForces* getInstance(wbi::iWholeBodyModel *);
  
  virtual const int numReturns();
  virtual bool allocateReturnSpace(int, mxArray*[]);
  virtual bool display(int, const mxArray *[]);
  virtual bool compute(int, const mxArray *[]);
  ~ModelGeneralisedBiasForces();
  
private:
  ModelGeneralisedBiasForces(wbi::iWholeBodyModel *);
  static ModelGeneralisedBiasForces *modelGeneralisedBiasForces;
  bool processArguments(int, const mxArray *[]);
  
  double *q;
  double *dq;
  double *dxb;
  double *h;
  double *g;
  const int numReturnArguments;
};

}

#endif // MODELGENERALISEDBIASFORCES_H
